//
//  ModelData.swift
//  surgeryView
//
//  Created by Tony Zhang on 4/18/24.
//

import Foundation
import SwiftUI
import RealityKit
import Network


//This class and only this class controls the display and processing of all data and events
//ModelManager.swift "listens" to this class automatically for all changes to models, imageSlices, etc

@Observable
class ModelData{
    var image: ImageMessage?
    
    //A pointer controlled by the cursor on 3d slicer, in the absense of input, fade out the cursor
    var pointerTransform: Transform = Transform.identity
    var pointerIsVisibile = false
    var pointerFadeDuration = 10
    var pointerFadeTime = Date.now
    
    var imageSlices: [Entity] {
        [axialSlice, coronalSlice, sagittalSlice].compactMap{$0}
    }
    var axialSlice: Entity?
    var coronalSlice: Entity?
    var sagittalSlice: Entity?
    var axialImageCache: [SimpleMaterial?]?
    var coronalImageCache: [SimpleMaterial?]?
    var sagittalImageCache: [SimpleMaterial?]?
    var slicesIsVisible = true
    
    var models: [Entity]
    var originTransform: Transform = Transform.identity
    var autoRotation = false
    var openIGTLinkServer: CommunicationsManager?
    var localIPAddress: String? 
    
    //one version of the code which shows an more detailed control panel, allowing for greater user interation
    var minimalUI = true
    
    private var _igtlRotation = simd_quatf.init(angle: Float.pi, axis: [0, 1, 0])
    
    init(models: [Entity] = []) {
        self.models = models
        
        //continuously update current IP address for network changes, etc.
        localIPAddress = self.getLocalIPAddress()
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.localIPAddress = self.getLocalIPAddress()
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            if self.autoRotation {
                self.originTransform.rotation = simd_quatf(angle: 0.1, axis: [0,1,0]) * self.originTransform.rotation
            }
        }
    }
    
    func startServer() {
        //The communications manager handles networking and parsing
        //this class, modelData, is used as a delegate to implement receiving messages, see extension below
        originTransform = Transform(scale: [0.002, 0.002, 0.002], rotation: _igtlRotation)
        openIGTLinkServer?.disconnect()
        openIGTLinkServer = CommunicationsManager(port: 18944, delegate: self)
        if let openIGTLinkServer {
            Task{
                openIGTLinkServer.startServer()
            }
        }
    }

    //Can be used for debug / demo purposes, instead of receiving models from network, it displays pre installed files
    func loadSampleModels() async{
        originTransform = Transform(scale: [0.1, 0.1, 0.1], rotation: simd_quatf.init(angle: -Float.pi/2, axis: [1, 0, 0]))
        let testModels = Bundle.main.urls(forResourcesWithExtension: "usdz", subdirectory: "")
        if let urls = testModels {
            let _models = try? await withThrowingTaskGroup(of: Optional<Entity>.self) { group in
                for model in urls {
                    group.addTask {
                        if let _model = try? await ModelEntity(named: model.lastPathComponent){
                            return _model
                        }
                        return nil
                    }
                }
                var models:[Entity?] = []
                for try await result in group {
                    models.append(result)
                }
                return models

            }
            models.append(contentsOf: _models?.compactMap({ $0 }) ?? [])
        }
    }
    
    func stressTestCubeGrid() {
        originTransform = Transform()
        for x in 0..<10 {
            for y in 0..<10 {
                for z in 0..<10{
                    let entity = ModelEntity(mesh: .generateBox(size: 0.008), materials: [UnlitMaterial(color: .init(white: 0, alpha: CGFloat(Float.random(in: 0...1))))])
                    entity.transform.translation  = [Float(x)/100, Float(y)/100, Float(z)/100]
                    models.append(entity)
                }
            }
        }
    }
    
    //Resets view, but preserves server connection
    func clearAll() {
        models = []
        axialSlice = nil
        coronalSlice = nil
        sagittalSlice = nil
        axialImageCache = nil
        coronalImageCache = nil
        sagittalImageCache = nil
        pointerIsVisibile = false
        image = nil
    }
    
    //only relevant with minimalUI = false, where the user can reposition models
    //otherwise, models are all positioned at the origin,
    //the actual positions of vertices determines where each model appears to be
    func resetPositions() {
        for entity in models {
            if let parent = entity.parent{
                entity.move(to: Transform(scale:entity.scale, translation: [0,0,0]), relativeTo: parent, duration: 0.2)
            }
        }
    }

    func explodeModels(_ factor: Float) {
        resetPositions()
        for entity in models {
            if let parent = entity.parent {
                let base = parent.parent
                let bounds = entity.visualBounds(relativeTo: base)
                let baseTransform = parent.convert(transform: entity.transform, to: base)
                entity.move(to: Transform(scale: baseTransform.scale, rotation: baseTransform.rotation, translation: (bounds.center + baseTransform.translation - [0, 0.1, 0]) * factor), relativeTo: base, duration: 0.5, timingFunction: .cubicBezier(controlPoint1: [0, 1], controlPoint2: [0.5, 1]))
            }
        }
    }
    
    //used to display DICOM slices with visibility and correctly mapped textures on both sides
    func generateDoubleSidedPlane(width: Float, height: Float, materials: [SimpleMaterial]) -> ModelEntity {
        let halfWidth = width / 2
        let halfHeight = height / 2

        let vertices: [SIMD3<Float>] = [
            // Front face
            SIMD3(-halfWidth, 0, -halfHeight),
            SIMD3(halfWidth, 0, -halfHeight),
            SIMD3(halfWidth, 0, halfHeight),
            SIMD3(-halfWidth, 0, halfHeight),
            // Back face
            SIMD3(-halfWidth, 0, -halfHeight),
            SIMD3(halfWidth, 0, -halfHeight),
            SIMD3(halfWidth, 0, halfHeight),
            SIMD3(-halfWidth, 0, halfHeight)
        ]

        let normals: [SIMD3<Float>] = [
            SIMD3(0, 1, 0),
            SIMD3(0, 1, 0),
            SIMD3(0, 1, 0),
            SIMD3(0, 1, 0),
            SIMD3(0, -1, 0),
            SIMD3(0, -1, 0),
            SIMD3(0, -1, 0),
            SIMD3(0, -1, 0)
        ]

        let uvs: [SIMD2<Float>] = [
            SIMD2(0, 0),
            SIMD2(1, 0),
            SIMD2(1, 1),
            SIMD2(0, 1),
            SIMD2(0, 0),
            SIMD2(1, 0),
            SIMD2(1, 1),
            SIMD2(0, 1)
        ]
        
        let indices: [UInt32] = [
            0, 1, 2, 0, 2, 3, // Front face
            4, 6, 5, 4, 7, 6  // Back face (reversed winding order)
        ]

        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffer(vertices)
        meshDescriptor.normals = MeshBuffer(normals)
        meshDescriptor.textureCoordinates = MeshBuffer(uvs)
        meshDescriptor.primitives = .triangles(indices)

        return ModelEntity(mesh: try! .generate(from: [meshDescriptor]), materials: materials)
    }
    
    //The following functions show DICOM IMAGES in all 3 directions
    //code for processing images is in OpenIGTLink/Image.swift
    func generateAxialSlice(position: Float) -> ModelEntity?{
        if let image = image{
            if let imageCache = axialImageCache {
                let index = (position - image.position.z + image.fullHeight/2)/image.normal.z
                let img = imageCache[min(max(Int(index),0),Int(image.size.z)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                //fade near top and bottom
                let plane = generateDoubleSidedPlane(width: Float(image.size.x)*image.traverse_i.x, height: Float(image.size.y)*image.traverse_j.y, materials: [img])
                plane.name = "axial-image"
                plane.position = rasToRealityKit(image.position)
                plane.position.y = position
                axialSlice = plane
                return plane
            }
        }
        return nil
    }
    
    func updateAxialSlice(position: Float){
        if let image = image {
            if let imageCache = axialImageCache{
                let index = (position - image.position.z + image.fullHeight/2)/image.normal.z
                let img = imageCache[min(max(Int(index),0),Int(image.size.z)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                (axialSlice as? ModelEntity)?.model?.materials = [img]
                axialSlice?.position.y = position
            }
        }
    }
    
    func generateCoronalSlice(position: Float) -> ModelEntity?{
        if let image = image{
            if let imageCache = coronalImageCache {
                let index = (-position - image.position.y + image.fullLength/2)/image.traverse_j.y
                let img = imageCache[min(max(Int(index),0),Int(image.size.y)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                let plane = generateDoubleSidedPlane(width: Float(image.size.x)*image.traverse_i.x, height: Float(image.size.z) * image.normal.z, materials: [img])
                plane.name = "coronal-image"
                plane.position = rasToRealityKit(image.position)
                plane.position.z = position
                plane.transform.rotation = simd_quatf.init(angle: Float.pi/2, axis: [1,0,0])
                coronalSlice = plane
                return plane
            }
        }
        return nil
    }
    
    func updateCoronalSlice(position: Float){
        if let image = image {
            if let imageCache = coronalImageCache{
                let index = (-position - image.position.y + image.fullLength/2)/image.traverse_j.y
                let img = imageCache[min(max(Int(index),0),Int(image.size.y)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                (coronalSlice as? ModelEntity)?.model?.materials = [img]
                coronalSlice?.position.z = position
            }
        }
    }
    func generateSagittalSlice(position: Float) -> ModelEntity?{
        if let image = image{
            if let imageCache = sagittalImageCache {
                let index = (position - image.position.x + image.fullWidth/2)/image.traverse_i.x
                let img = imageCache[min(max(Int(index),0),Int(image.size.x)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                //fade near top and bottom
                let plane = generateDoubleSidedPlane(width: image.fullHeight, height: image.fullLength, materials: [img])
                plane.name = "sagittal-image"
                plane.position = rasToRealityKit(image.position)
                plane.position.x = (position)
                plane.transform.rotation = .init(angle: Float.pi/2, axis: [0,0,1])
                sagittalSlice = plane
                return plane
            }
        }
        return nil
    }
    
    func updateSagittalSlice(position: Float){
        if let image = image {
            if let imageCache = sagittalImageCache{
                let index = (position - image.position.x + image.fullWidth/2)/image.traverse_i.x
                let img = imageCache[min(max(Int(index),0),Int(image.size.x)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                (sagittalSlice as? ModelEntity)?.model?.materials = [img]
                sagittalSlice?.position.x = position
            }
        }
    }
     
    func sendSlicePosition(name: String, pos: Float){
        openIGTLinkServer?.sendMessage(header: IGTHeader.create(messageType: "STRING", name: name), content: StringMessage(str: String(describing: pos)))
    }
    
    func sendEntity(entity: Entity){
        openIGTLinkServer?.sendMessage(header: IGTHeader.create(messageType: "STRING", name: "ENTITY"), content: StringMessage(str: entity.name))
    }

    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { return "" }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    let name: String = String(cString: (interface.ifa_name))
                    if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        //checks if address is ipv4
                        guard interface.ifa_addr.pointee.sa_family == 2 else {continue}
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? ""
    }
}

extension ModelData: OpenIGTDelegate {
    //to achieve fast volume slices rendering and interaction, each slice is generated and cached as a material
    //this is only part of the processing; ImageMessage already processes data and converts to CGImages
    func receiveImageMessage(header: IGTHeader, image img: ImageMessage) {
        self.image = img
        Task{
            self.image?.setImageData()
            Task {
                await withTaskGroup(of: Optional<(SimpleMaterial,Int)>.self) { group in
                    for i in 0..<image!.size.z {
                        group.addTask {
                            if let img = self.image!.createAxialImage(position: Int(i)) {
                                if let texture = try? await TextureResource.generate(from: img, options: .init(semantic: .color)){
                                    var material = SimpleMaterial()
                                    material.color =  .init(texture: .init(texture))
                                    return (material,Int(i))
                                }
                            }
                            return nil
                        }
                    }
                    
                    axialImageCache = Array<SimpleMaterial?>(repeating: nil, count: Int(image!.size.z))
                    for await result in group {
                        if let result = result {
                            axialImageCache?[result.1] = result.0
                        }
                    }
                }
                Task.detached { @MainActor in
                    //                self.generateImageSlices()
                    self.generateAxialSlice(position: self.image!.position.z)
                }
            }
            Task {
                await withTaskGroup(of: Optional<(SimpleMaterial,Int)>.self) { group in
                    for i in 0..<image!.size.y {
                        group.addTask {
                            if let img = self.image!.createCoronalImage(position: Int(i)) {
                                if let texture = try? await TextureResource.generate(from: img, options: .init(semantic: .color)){
                                    var material = SimpleMaterial()
                                    material.color =  .init(texture: .init(texture))
                                    return (material,Int(i))
                                }
                            }
                            return nil
                        }
                    }
                    
                    coronalImageCache = Array<SimpleMaterial?>(repeating: nil, count: Int(image!.size.y))
                    for await result in group {
                        if let result = result {
                            coronalImageCache?[result.1] = result.0
                        }
                    }
                }
                Task.detached { @MainActor in
                    //                self.generateImageSlices()
                    self.generateCoronalSlice(position: -self.image!.position.y)
                }
            }
            Task {
                await withTaskGroup(of: Optional<(SimpleMaterial,Int)>.self) { group in
                    for i in 0..<image!.size.x {
                        group.addTask {
                            if let img = self.image!.createSagittalImage(position: Int(i)) {
                                if let texture = try? await TextureResource.generate(from: img, options: .init(semantic: .color)){
                                    var material = SimpleMaterial()
                                    material.color =  .init(texture: .init(texture))
                                    return (material,Int(i))
                                }
                            }
                            return nil
                        }
                    }
                    
                    sagittalImageCache = Array<SimpleMaterial?>(repeating: nil, count: Int(image!.size.x))
                    for await result in group {
                        if let result = result {
                            sagittalImageCache?[result.1] = result.0
                        }
                    }
                }
                Task.detached { @MainActor in
                    self.generateSagittalSlice(position: self.image!.position.x)
                }
            }
        }
    }
    
    func receiveTransformMessage(header: IGTHeader, transform: TransformMessage) {
        //transform messages either convey orientation information to the camera, or
        //the position of the pointer
        if header.deviceName.trimmingCharacters(in: ["\0"]) == "CAMERA" {
            originTransform.rotation = transform.realityKitTransform().rotation
        } else {
            pointerIsVisibile = true
            pointerTransform = transform.realityKitTransform()
            pointerFadeTime = Date.now.addingTimeInterval(TimeInterval(pointerFadeDuration))
            Task {
                try await Task.sleep(nanoseconds: UInt64(pointerFadeDuration * 1_000_000_000))
                if Date.now > pointerFadeTime{
                    pointerIsVisibile = false
                }
            }
        }
    }
    
    func receivePolyDataMessage(header: IGTHeader, polydata: PolyDataMessage) {
        let model = ModelEntity()
        model.model = ModelComponent(mesh: .generateBox(size: 0), materials: [UnlitMaterial(color: .clear)])
        
        //ModelEntity must be created immediately for subsequent messages that set color and opacity
        //Mesh is separate from the model and can be edited at any time afterwords,
        //so the relativelty expensive task of generating polygons can be done concurrently to not block main thread
        Task(priority: .high){
            if let mesh = polydata.generateMeshFromPolys() {
                Task.detached { @MainActor in
                    model.model?.mesh = mesh
                }
            }
        }
        
        model.name = header.deviceName
        model.components.set(OpacityComponent(opacity: 0))
        model.components.set(GroundingShadowComponent(castsShadow: true))
        
        models.append(model)
    }
    
    //any misc information is sent through a string message, attaching metadata directly does not seem to be available on the 3d slicer side.
    func receiveStringMessage(header: IGTHeader, string: StringMessage) {
        switch header.deviceName.trimmingCharacters(in: ["\0"]) {
        case "CLEAR":
            clearAll()
        case "MODELCOLOR":
            let str = string.str
            let _split = str.split(separator: "---")
            let colorInfo = _split[1]
            var color = UIColor.white
            if colorInfo.count >= 3 {
                var rgbValue:UInt64 = 0
                Scanner(string: colorInfo.trimmingCharacters(in: ["#","\0"]).uppercased()).scanHexInt64(&rgbValue)
                color = UIColor(
                    red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                    green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                    blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                    alpha: CGFloat(1)
                )
            }
            var material = PhysicallyBasedMaterial()
            material.roughness = 0.3
            material.baseColor = .init(tint: color)
            
            (models.filter{_split[0].hasPrefix( $0.name)}.first as? ModelEntity)?.model?.materials = [material]
            
        case "MODELVISIBILITY":
            let str = string.str
            let _split = str.split(separator: "---")
            let opacity = (_split[1] as NSString).floatValue
            
            let model = (models.filter{_split[0].hasPrefix( $0.name)}.first as? ModelEntity)
            model?.isEnabled = opacity != 0
            model?.components.set(OpacityComponent(opacity: opacity))
            

            
        case "AXIAL":
            let pos = Float(string.str) ?? 0
            updateAxialSlice(position: pos)
        case "CORONAL":
            let pos = Float(string.str) ?? 0
            updateCoronalSlice(position: -pos)
        case "SAGGITAL":
            let pos = Float(string.str) ?? 0
            updateSagittalSlice(position: -pos)
        case "DICOM":
            if string.str == "DISABLE"{
                slicesIsVisible = false
            } else { slicesIsVisible = true }
        default:
            break
        }
    }
}
