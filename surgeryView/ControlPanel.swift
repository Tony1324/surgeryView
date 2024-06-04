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
                NavigationLink {
                    List{
                        
                        Button {
                            Task{
                                modelData.clearAll()
                            }
                        } label: {
                            Text("Clear all models")
                        }
                        Button {
                            Task{
                                modelData.clearAll()
                                await modelData.loadSampleModels()
                            }
                        } label: {
                            Text("Load Sample Scene")
                        }
                        
                        Button {
                            Task{
                                modelData.clearAll()
                                modelData.startServer()
                            }
                        } label: {
                            Text("Begin OpenIGTLink Connection")
                        }
                        
                    }
                    .navigationTitle("Scenes")
                } label: {
                    Text("Scenes")
                }
                NavigationLink {
                    //TODO: update to multiselect
                        List{
                            ForEach(modelData.models){ entity in
                                Button{
                                    if(modelData.selectedEntity == entity) {
                                        modelData.selectedEntity = nil
                                    } else {
                                        modelData.selectedEntity = entity
                                    }
                                }label:{
                                    Text(entity.name.isEmpty ? "Unnamed Object" : entity.name)
                                }
                                
                            }
                        }
                        .navigationTitle("Models")

                } label: {
                    Text("Models")
                }
                
            }
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
                        modelData.explodeModels(1)
                    } label: {
                        Label("Explode Models", systemImage: "arrow.up.backward.and.arrow.down.forward.square")
                    }
                }
            })
            .listStyle(.sidebar)
            .navigationTitle("Controls")
        }
        
    }
}

#Preview {
    ControlPanel()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
