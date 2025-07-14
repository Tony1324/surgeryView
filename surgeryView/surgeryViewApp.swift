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
    @Environment(\.scenePhase) private var scenePhase

    var body: some SwiftUI.Scene {

        WindowGroup {
            ContentView()
                .environment(modelData)
        }
        .windowStyle(.volumetric)
        //dynamic maintains relative size of models in field of view, so that if the window is moved away, the size is increased as well
        .defaultWorldScaling(.automatic)
        //gravity aligned maintains that the volume does not tilt, instead keeping its vertical axis
        .volumeWorldAlignment(.gravityAligned)
        .defaultSize(width: 1.6, height: 1.6, depth: 1.6, in: .meters)
    }
}
