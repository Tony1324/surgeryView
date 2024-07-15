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

@Observable
class ModelData{
    var image: ImageMessage?
    var pointerTransform: Transform = Transform.identity
    var imageSlices: [Entity] {
        [axialSlice, coronalSlice, sagittalSlice].compactMap{$0}
    }
    var axialSlice: Entity?
    var coronalSlice: Entity?
    var sagittalSlice: Entity?
    var axialImageCache: [SimpleMaterial?]?
    var coronalImageCache: [SimpleMaterial?]?
    var sagittalImageCache: [SimpleMaterial?]?
    var models: [Entity]
    var selectedEntity: Entity?
    var originTransform: Transform = Transform.identity
    var igtlClient: CommunicationsManager?

    init(models: [Entity] = []) {
        self.models = models
    }
    
    func startServer() {
        //The communications manager handles networking and parsing
        //this class, modelData, is used as a delegate to implement receiving messages, see extension below
        originTransform = Transform(scale: [0.001, 0.001, 0.001], rotation: simd_quatf.init(angle: Float.pi, axis: [0, 1, 0]))
        igtlClient?.disconnect()
        igtlClient = CommunicationsManager(port: 18944, delegate: self)
        if let igtlClient {
            Task{
                await igtlClient.startClient()
//                let message = IGTHeader(v: 2, messageType: "GET_POLYDATA", deviceName: "Client", timeStamp: 0, bodySize: 0, CRC: 0)
//                igtlClient.sendMessage(header: message, content: NoneMessage())
            }
        }
    }

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
    
    func clearAll() {
        selectedEntity = nil
        models = []
        axialSlice = nil
        coronalSlice = nil
        sagittalSlice = nil
        axialImageCache = nil
        coronalImageCache = nil
        sagittalImageCache = nil
        image = nil
    }
    
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
            SIMD2(0, 1),
            SIMD2(1, 1),
            SIMD2(1, 0),
            SIMD2(0, 0),
            SIMD2(0, 1),
            SIMD2(1, 1),
            SIMD2(1, 0),
            SIMD2(0, 0)
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
                let img = imageCache[min(max(Int(position/image.normal.z),0),Int(image.size.z)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                //fade near top and bottom
                let plane = generateDoubleSidedPlane(width: Float(image.size.x)*image.traverse_i.x, height: Float(image.size.x)*image.traverse_j.y, materials: [img])
                plane.name = "axial-image"
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
                let img = imageCache[min(max(Int(position/image.normal.z),0),Int(image.size.z)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                (axialSlice as? ModelEntity)?.model?.materials = [img]
            }
        }
    }
    
    func generateCoronalSlice(position: Float) -> ModelEntity?{
        if let image = image{
            if let imageCache = coronalImageCache {
                let img = imageCache[min(max(Int(position/image.traverse_j.y),0),Int(image.size.y)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                let plane = generateDoubleSidedPlane(width: Float(image.size.x)*image.traverse_i.x, height: Float(image.size.z) * image.normal.z, materials: [img])
                plane.name = "coronal-image"
                plane.position.z = (Float(image.size.x/2) - position)*image.traverse_j.y
                plane.position.y = Float(image.size.z) * Float(image.normal.z) / 2
                plane.transform.rotation = simd_quatf.init(angle: -Float.pi/2, axis: [1,0,0])
                coronalSlice = plane
                return plane
            }
        }
        return nil
    }
    
    func updateCoronalSlice(position: Float){
        if let image = image {
            if let imageCache = coronalImageCache{
                let img = imageCache[min(max(Int(position),0),Int(image.size.y)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                (coronalSlice as? ModelEntity)?.model?.materials = [img]
            }
        }
    }
    func generateSagittalSlice(position: Float) -> ModelEntity?{
        if let image = image{
            if let imageCache = sagittalImageCache {
                let img = imageCache[min(max(Int(position/image.traverse_i.x),0),Int(image.size.x)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                //fade near top and bottom
                let plane = generateDoubleSidedPlane(width: Float(image.size.y)*image.traverse_j.y, height: Float(image.size.z) * image.normal.z, materials: [img])
                plane.name = "sagittal-image"
                plane.position.x = (Float(image.size.x)/2 - position)*image.traverse_i.x
                plane.position.y = Float(image.size.z) * Float(image.normal.z) / 2
                plane.transform.rotation = .init(angle: -Float.pi/2, axis: [0,0,1]) * .init(angle: -Float.pi/2, axis: [0, 1, 0])
                sagittalSlice = plane
                return plane
            }
        }
        return nil
    }
    
    func updateSagittalSlice(position: Float){
        if let image = image {
            if let imageCache = sagittalImageCache{
                let img = imageCache[min(max(Int(position),0),Int(image.size.x)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                (sagittalSlice as? ModelEntity)?.model?.materials = [img]
            }
        }
    }

}

extension ModelData: OpenIGTDelegate {
    func receiveImageMessage(header: IGTHeader, image img: ImageMessage) {
        self.image = img
        Task{
            self.image?.scaleImageData()
            Task {
                await withTaskGroup(of: Optional<(SimpleMaterial,Int)>.self) { group in
                    axialImageCache = []
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
                    for _ in 0..<image!.size.z {
                        axialImageCache?.append(nil)
                    }
                    for await result in group {
                        if let result = result {
                            axialImageCache?[result.1] = result.0
                        }
                    }
                }
                Task.detached { @MainActor in
                    //                self.generateImageSlices()
                    self.generateAxialSlice(position: 0)
                }
            }
            Task {
                self.image?.coronalTranposedImage()
                
                await withTaskGroup(of: Optional<(SimpleMaterial,Int)>.self) { group in
                    coronalImageCache = []
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
                    for _ in 0..<image!.size.y {
                        coronalImageCache?.append(nil)
                    }
                    for await result in group {
                        if let result = result {
                            coronalImageCache?[result.1] = result.0
                        }
                    }
                }
                Task.detached { @MainActor in
                    //                self.generateImageSlices()
                    self.generateCoronalSlice(position: 0)
                }
            }
            Task {
                self.image?.sagittalTransposedImage()
                await withTaskGroup(of: Optional<(SimpleMaterial,Int)>.self) { group in
                    sagittalImageCache = []
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
                    for _ in 0..<image!.size.x {
                        sagittalImageCache?.append(nil)
                    }
                    for await result in group {
                        if let result = result {
                            sagittalImageCache?[result.1] = result.0
                        }
                    }
                }
                Task.detached { @MainActor in
                    self.generateSagittalSlice(position: 0)
                }
            }
        }
    }
    func receiveTransformMessage(header: IGTHeader, transform: TransformMessage) {
        print("Transform recieved!")
        pointerTransform = transform.realityKitTransform()
    }
    func receivePolyDataMessage(header: IGTHeader, polydata: PolyDataMessage) {
        print("polydata recieved!")
        if let model = polydata.generateModelEntityFromPolys() {
            let colorInfo = header.deviceName
            var color = UIColor.white
            if colorInfo.count >= 3{
                var rgbValue:UInt64 = 0
                Scanner(string: colorInfo.trimmingCharacters(in: ["#","\0"]).uppercased()).scanHexInt64(&rgbValue)
                color = UIColor(
                    red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                    green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                    blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                    alpha: CGFloat(1)
                )
            }
            model.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
            models.append(model)
        }
    }
}
