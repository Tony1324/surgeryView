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
