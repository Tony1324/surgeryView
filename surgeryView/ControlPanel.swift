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
                            Text("OpenIGTLink Connection")
                        }
                        Button {
                            Task{
                                modelData.clearAll()
                                modelData.loadShaderTest()
                            }
                        } label: {
                            Text("Image Test")
                        }
                        Button {
                            Task{
                                modelData.clearAll()
                                modelData.stressTestCubeGrid()
                            }
                        } label: {
                            Text("Performance Test")
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
            
            .listStyle(.sidebar)
            .navigationTitle("Controls")
        }
        
    }
}

#Preview {
    ControlPanel()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
