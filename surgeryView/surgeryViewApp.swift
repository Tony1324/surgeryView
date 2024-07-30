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
                .task {
                    if(modelData.igtlClient == nil){
                        modelData.startServer()
                    }
                }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.8, height: 2, depth: 0.8, in: .meters)
        

//        ImmersiveSpace(id: "3d-immersive") {
//            ContentView()
//                .environment(modelData)
//                .task {
//                    if(modelData.igtlClient == nil){
//                        modelData.startServer()
//                    }
//                }
//        }
//        .immersionStyle(selection: $style, in: .mixed)
    }
}
