//
//  surgeryViewApp.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/3/24.
//

import SwiftUI
import RealityKit



extension Entity: Observable{

}

@Observable
class ModelData: ObservableObject {
    var images: [Entity]
    var models: [Entity]

    init(images: [Entity] = [], models: [Entity] = []) {
        self.images = images
        self.models = models
    }
}

@main
struct surgeryViewApp: App {

    @State private var modelData = ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.5, cornerRadius: 0.1), materials: [SimpleMaterial(color: .blue, isMetallic: true)])])

    var body: some SwiftUI.Scene {
        WindowGroup(id:"control-panel"){
            ControlPanel()
                .environment(modelData)
        }
        .defaultSize(CGSize(width: 250, height: 400))


        WindowGroup {
            ContentView()
                .environment(modelData)
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
