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
            if let parent = entity.parent{
                entity.move(to: Transform(scale:entity.scale, translation: [0,0,0]), relativeTo: parent, duration: 0.2)
            }
        }
    }

    func explodeModels(_ factor: Float) {
        for entity in models {
            let bounds = entity.visualBounds(relativeTo: entity.parent)
            let center = bounds.center
            entity.move(to: Transform(scale: entity.scale, translation: center*factor), relativeTo: entity.parent, duration: 0.2)
        }
    }
}

@main
struct surgeryViewApp: App {

    @State private var modelData = ModelData(models: [])
    @State var style: ImmersionStyle = .mixed
    @Environment(\.openImmersiveSpace) var openImmersiveSpace

    var body: some SwiftUI.Scene {
        WindowGroup(id:"control-panel"){
            ControlPanel()
                .environment(modelData)
                .task {
                    await openImmersiveSpace(id: "3d-immersive")
                }
        }
        .defaultSize(CGSize(width: 250, height: 400))

        ImmersiveSpace(id: "3d-immersive") {
            ContentView()
                .environment(modelData)
                .frame(depth: 1000)
        }
        .immersionStyle(selection: $style, in: .mixed)
    }
}
