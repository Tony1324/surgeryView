//
//  ContentView.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/3/24.
//

import SwiftUI
import RealityKit

struct ContentView: View {

    @State private var moveContent = false
    @State private var translationOffset: Float = 0.0
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    private var sampleObject = ModelEntity(mesh: .generateBox(size: 0.4, cornerRadius: 0.05), materials: [SimpleMaterial(color: .blue, isMetallic: true)])
    @Environment(ModelData.self) var modelData
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        ModelManager()
            .onAppear{
                openWindow(id: "control-panel")
            }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
