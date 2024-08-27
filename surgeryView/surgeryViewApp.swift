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

        WindowGroup {
            ContentView()
                .environment(modelData)
        }
        .windowStyle(.volumetric)
        .defaultWorldScaling(.dynamic)
        .volumeWorldAlignment(.gravityAligned)
        .defaultSize(width: 0.8, height: 0.8, depth: 0.8, in: .meters)
    }
}
