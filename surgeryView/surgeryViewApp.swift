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
}

@main
struct surgeryViewApp: App {

    @State private var modelData = ModelData(models: [])

    var body: some SwiftUI.Scene {
        WindowGroup(id:"control-panel"){
            ControlPanel()
                .environment(modelData)
                .task {
                    let testModels = Bundle.main.urls(forResourcesWithExtension: "usdz", subdirectory: "")
                    modelData.models = []
                    if let urls = testModels {
                        print("loading test models")
                        await withTaskGroup(of: Void.self) { group in
                            for model in urls {
                                group.addTask {
                                    if let _model = try? await ModelEntity(named: model.lastPathComponent){
                                        modelData.models.append(_model)
                                    }
                                }
                            }
                        }
                    }
                }
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
