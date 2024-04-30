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
    var igtlClient: CommunicationsManager?

    init(images: [Entity] = [], models: [Entity] = []) {
        self.images = images
        self.models = models
    }
    
    func startServer() {
        igtlClient = CommunicationsManager(host: "127.0.0.1", port: 8267)
        if let igtlClient {
            igtlClient.startClient()
        }
    }
    
    func loadSampleModels() async{
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
            models = _models?.compactMap({ $0 }) ?? []
        }
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
