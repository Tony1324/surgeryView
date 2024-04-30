//
//  surgeryViewApp.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/3/24.
//

import Foundation
import SwiftUI
import RealityKit
import Network

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
                .task {
                    modelData.startServer()
                }
        }
        .immersionStyle(selection: $style, in: .mixed)
    }
}
