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
    
    var imageOffset: Float = 0
    var imageCount: Int = 5
    var imageSlices: [Entity]
    var image: ImageMessage?
    var imageCache: [SimpleMaterial?]?
    var models: [Entity]
    var selectedEntity: Entity?
    var originTransform: Transform = Transform.identity
    var igtlClient: CommunicationsManager?

    init(images: [Entity] = [], models: [Entity] = []) {
        self.imageSlices = images
        self.models = models
    }
    
    func startServer() {
        //The communications manager handles networking and parsing
        //this class, modelData, is used as a delegate to implement receiving messages, see extension below
        originTransform = Transform(scale: [0.001, 0.001, 0.001], rotation: simd_quatf.init(angle: Float.pi, axis: [0, 1, 0]))
        igtlClient?.disconnect()
        igtlClient = CommunicationsManager(host: "10.246.98.237", port: 2200, delegate: self)
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
    
    func loadShaderTest() {
        originTransform = Transform()
        let plane = ModelEntity(mesh: .generatePlane(width: 0.5, depth: 0.5), materials: [SimpleMaterial(color: .black,roughness: 0, isMetallic: false)])
        plane.name = "image"
        imageSlices.append(plane)
    }
    
    
    func clearAll() {
        selectedEntity = nil
        models = []
        imageSlices = []
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
    
    func generateImageSlice(position: Float) -> ModelEntity?{
        if let image = image{
            if let imageCache = imageCache {
                var img = imageCache[min(max(Int(position/image.normal.z),0),Int(image.size.z)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                //fade near top and bottom
                let opacity = min(0.5, min(0.5 + position / 20, 0.5 + (Float(image.size.z) * Float(image.normal.z) - position) / 20 ))
                img.color.tint = .white.withAlphaComponent(CGFloat(opacity))
                let plane = ModelEntity(mesh: .generatePlane(width: Float(image.size.x), depth: Float(image.size.y)), materials: [img])
                plane.name = "image"
                plane.position.y = position
                imageSlices.append(plane)
                return plane
            }
        }
        return nil
    }
    
    func updateImageEntityPosition(_ entity: Entity, position: Float){
        if let image = image {
            if let imageCache = imageCache{
                var img = imageCache[min(max(Int(position/image.normal.z),0),Int(image.size.z)-1)] ?? SimpleMaterial(color: .black, isMetallic: false)
                let opacity = min(0.5, min(0.5+position / 20, 0.5 + (Float(image.size.z) * Float(image.normal.z) - position) / 20 ))
                img.color.tint = .white.withAlphaComponent(CGFloat(opacity))
                (entity as? ModelEntity)?.model?.materials = [img]
            }
        }
    }

    func generateImageSlices() {
        if let image = image {
            var pos = Float(-20)
            while (pos <= image.fullHeight + 20) {
                let plane = generateImageSlice(position: pos)
                plane?.position.y = pos
                pos += image.fullHeight / Float(imageCount)
            }
        }
    }
}


extension ModelData: OpenIGTDelegate {
    func receiveImageMessage(header: IGTHeader, image: ImageMessage) {
        self.image = image
        Task {
            await withTaskGroup(of: Optional<(SimpleMaterial,Int)>.self) { group in
                imageCache = []
                for i in 0..<image.size.z {
                    group.addTask {
                        if let img = image.createImage(position: Int(i)) {
                            if let texture = try? await TextureResource.generate(from: img, options: .init(semantic: .color)){
                                var material = SimpleMaterial()
                                material.color =  .init(texture: .init(texture))
                                return (material,Int(i))
                            }
                        }
                        return nil
                    }
                }
                for _ in 0..<image.size.z {
                    imageCache?.append(nil)
                }
                for await result in group {
                    if let result = result {
                        imageCache?[result.1] = result.0
                    }
                }
            }
            Task.detached { @MainActor in
                self.generateImageSlices()
            }
        }
    }
    func receiveTransformMessage(header: IGTHeader, transform: TransformMessage) {
        print("Transform recieved!")
    }
    func receivePolyDataMessage(header: IGTHeader, polydata: PolyDataMessage) {
        print("polydata recieved!")
        if let model = polydata.generateModelEntityFromPolys() {
            models.append(model)
        }
    }
}
