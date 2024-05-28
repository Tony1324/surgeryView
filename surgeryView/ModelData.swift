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
    var originTransform: Transform = Transform.identity
    var igtlClient: CommunicationsManager?

    init(images: [Entity] = [], models: [Entity] = []) {
        self.images = images
        self.models = models
    }
    
    func startServer() {
        //The communications manager handles networking and parsing
        //this class, modelData, is used as a delegate to implement receiving messages, see extension below
        originTransform = Transform(scale: [0.001, 0.001, 0.001], rotation: simd_quatf.init(angle: Float.pi, axis: [0, 1, 0]), translation: [0, 1, -1.5])
        igtlClient?.disconnect()
        igtlClient = CommunicationsManager(host: "10.15.236.219", port: 2200, delegate: self)
        if let igtlClient {
            Task{
                await igtlClient.startClient()
//                let message = IGTHeader(v: 2, messageType: "GET_POLYDATA", deviceName: "Client", timeStamp: 0, bodySize: 0, CRC: 0)
//                igtlClient.sendMessage(header: message, content: NoneMessage())
            }
        }
    }
    
    func loadSampleModels() async{
        originTransform = Transform(scale: [0.1, 0.1, 0.1], rotation: simd_quatf.init(angle: -Float.pi/2, axis: [1, 0, 0]), translation: [0, 1, -1.5])
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
    
    func clearAll() {
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
            let bounds = entity.visualBounds(relativeTo: entity.parent)
            var center = bounds.center
            center.z = center.z - (entity.parent?.findEntity(named: "base")?.position.z ?? 0) - 1
            print(entity.parent?.findEntity(named: "base")?.position)
            entity.move(to: Transform(scale: entity.scale, translation: center*factor), relativeTo: entity.parent, duration: 0.2, timingFunction: .easeOut)
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
