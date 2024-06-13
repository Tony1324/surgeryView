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


        ImmersiveSpace(id: "3d-immersive") {
            ContentView()
                .environment(modelData)
                .task {
                    await modelData.loadSampleModels()
                }
        }
        .immersionStyle(selection: $style, in: .mixed)
    }
}
