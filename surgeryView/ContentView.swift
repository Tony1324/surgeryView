//
//  ContentView.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/3/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var moveContent = false
    @State private var translationOffset: Float = 0.0
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    private var sampleObject = ModelEntity(mesh: .generateBox(size: 0.5, cornerRadius: 0.1), materials: [SimpleMaterial(color: .blue, isMetallic: true)])
    @EnvironmentObject var ModelData: ModelData
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        ZStack (alignment: .bottom) {
            ModelManager()
                .onAppear{
                    ModelData.models = [sampleObject, ModelEntity(mesh: .generateSphere(radius: 0.2), materials: [PhysicallyBasedMaterial()])]
                }
            Button {
                openWindow(id: "control-panel")
            } label: {
                Label("Open Control Panel", systemImage: "info.circle")
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
