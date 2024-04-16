//
//  ControlPanel.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/24/24.
//

import SwiftUI
import RealityKit

struct ControlPanel: View {
    @Environment(ModelData.self) var modelData: ModelData
    @Environment(\.openWindow) var openWindow
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    var body: some View {
        NavigationStack{

                List{
                    Text("Model Visibility")
                        .font(.title)
                    ForEach(modelData.models){ entity in
                        Button{
                            entity.isEnabled.toggle()
                        }label:{
                            Text(entity.name.isEmpty ? "Unnamed Object" : entity.name)
                        }

                    }
                }
                .listStyle(.plain)
                .listStyle(.sidebar)
                .toolbar(content: {
                    ToolbarItem(placement: .bottomOrnament) {
                        Button {
                            Task{
                                await openImmersiveSpace(id: "3d-immersive")
                            }
                        } label: {
                            Label("Open Immersive Space", systemImage: "cube")
                        }
                    }
                    ToolbarItem(placement: .bottomOrnament) {
                        Button {
                            modelData.resetPositions()
                        } label: {
                            Label("Reset Positions", systemImage: "arrow.counterclockwise.circle")
                        }
                    }
                    ToolbarItem(placement: .bottomOrnament) {
                        Button {
                            modelData.explodeModels(2)
                        } label: {
                            Label("Explode Models", systemImage: "arrow.up.backward.and.arrow.down.forward.square")
                        }
                    }
                })
        }
        .navigationTitle("Models")
    }
}

#Preview {
    ControlPanel()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
