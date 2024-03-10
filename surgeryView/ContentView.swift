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
    @State private var showContent = true
    @State private var translationOffset: Float = 0.0
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack {
            RealityView { content in
                // Add the initial RealityKit content
                if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {

                    content.add(scene)
                    content.add(scene.clone(recursive: true))

                }
            } update: { content in
                // Update the RealityKit content when SwiftUI state changes
                if let scene = content.entities.first {
                    let translation: Float = moveContent ? -0.3 : 0.3
                    scene.transform.translation = [translation, 0,0]
                    scene.isEnabled = showContent
                }
            }
            .gesture(TapGesture().targetedToAnyEntity().onEnded { _ in
                moveContent.toggle()
            })

            VStack (spacing: 12) {
                Toggle("Move Content", isOn: $moveContent)
                    .font(.title)

                Toggle("Show Content", isOn: $showContent)
                    .font(.title)
            }
            .frame(width: 360)
            .padding(36)
            .glassBackgroundEffect()

        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
