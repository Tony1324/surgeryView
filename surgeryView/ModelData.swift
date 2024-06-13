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
    
    
    var images: [Entity]
    var models: [Entity]
    var selectedEntity: Entity?
    var originTransform: Transform = Transform.identity
    var igtlClient: CommunicationsManager?

    init(images: [Entity] = [], models: [Entity] = []) {
        self.images = images
        self.models = models
    }
    
    func startServer() {
        //The communications manager handles networking and parsing
        //this class, modelData, is used as a delegate to implement receiving messages, see extension below
        originTransform = Transform(scale: [0.001, 0.001, 0.001], rotation: simd_quatf.init(angle: Float.pi, axis: [0, 1, 0]))
        igtlClient?.disconnect()
        igtlClient = CommunicationsManager(host: "10.15.253.62", port: 2200, delegate: self)
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
        images.append(plane)
    }
    
    
    func clearAll() {
        selectedEntity = nil
        models = []
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
                var center = bounds.center
                let baseTransform = parent.convert(transform: entity.transform, to: base)
                entity.move(to: Transform(scale: baseTransform.scale, rotation: baseTransform.rotation, translation: (bounds.center + baseTransform.translation - [0, 0.1, 0]) * factor), relativeTo: base, duration: 0.5, timingFunction: .cubicBezier(controlPoint1: [0, 1], controlPoint2: [0.5, 1]))
            }
        }
    }
}


extension ModelData: OpenIGTDelegate {
    func receiveTransformMessage(header: IGTHeader, polydata: TransformMessage) {
        print("Transform recieved!")
    }
    func receivePolyDataMessage(header: IGTHeader, polydata: PolyDataMessage) {
        print("polydata recieved!")
        if let model = polydata.generateModelEntityFromPolys() {
            models.append(model)
        }
    }
}
