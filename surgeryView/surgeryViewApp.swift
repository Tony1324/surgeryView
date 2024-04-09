//
//  surgeryViewApp.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/3/24.
//

import Foundation
import SwiftUI
import RealityKit



extension Entity: Observable{

}

@Observable
class ModelData{
    
    var images: [Entity]
    var models: [Entity]

    init(images: [Entity] = [], models: [Entity] = []) {
        self.images = images
        self.models = models
    }
    
    func loadSampleModels() async{
        let testModels = Bundle.main.urls(forResourcesWithExtension: "usdz", subdirectory: "")
        if let urls = testModels {
            print("loading test models")
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
            entity.position = [0,0,0]
        }
    }
}

@main
struct surgeryViewApp: App {

    @State private var modelData = ModelData(models: [])

    var body: some SwiftUI.Scene {
        WindowGroup(id:"control-panel"){
            ControlPanel()
                .environment(modelData)
        }
        .defaultSize(CGSize(width: 250, height: 400))

        ImmersiveSpace(id: "3d-immersive") {
            ContentView()
                .environment(modelData)
                .frame(depth: 1000)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
