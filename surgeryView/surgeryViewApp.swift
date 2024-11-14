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
                .onChange(of: scenePhase) {
                    //if the main volume is closed, the saved models and patient data is reset, but connection is maintained
                    if scenePhase == .background {
                        modelData.clearAll()
                    }
                }
        }
        .windowStyle(.volumetric)
        //dynamic maintains relative size of models in field of view, so that if the window is moved away, the size is increased as well
        .defaultWorldScaling(.dynamic)
        //gravity aligned maintains that the volume does not tilt, instead keeping its vertical axis
        .volumeWorldAlignment(.gravityAligned)
        .defaultSize(width: 0.8, height: 0.8, depth: 0.8, in: .meters)
    }
}
