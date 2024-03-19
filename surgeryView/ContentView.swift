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

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    private var sampleObject = ModelEntity(mesh: .generateBox(size: 0.5, cornerRadius: 0.1), materials: [SimpleMaterial(color: .blue, isMetallic: true)])
    @State private var entities: [Entity] = []

    var body: some View {
        ZStack (alignment: .bottom) {
            ModelManager(entities: entities)
                .onAppear{
                    entities = [sampleObject, ModelEntity(mesh: .generateSphere(radius: 0.2), materials: [PhysicallyBasedMaterial()])]
                }
            VStack {
                Button {
                    moveContent.toggle()
                    sampleObject.transform.scale = moveContent ? [1.5, 1.5, 1.5] : [1, 1, 1]
                } label: {
                    Label("Toggle Size", systemImage: "arrow.up.left.and.arrow.down.right")

                }
            }
            .frame(width: 360, alignment: .bottom)
            .padding(36)
            .glassBackgroundEffect()
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
