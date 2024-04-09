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
            VStack{

                List{
                    Section ("Models Visibility"){
                        ForEach(modelData.models){ entity in
                            Button{
                                entity.isEnabled.toggle()
                            }label:{
                                Text("Toggle \(entity.name.isEmpty ? "Unnamed Object" : entity.name)")
                            }

                        }
                    }
                }
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 16))
                .padding()
                .listStyle(.grouped)
                Button {
//                    modelData.resetPositions()
                    for entity in modelData.models {
                        print(modelData.models.count)
                        entity.position = [0,0,0]
                    }
                } label: {
                    Label("Reset Positions", systemImage: "arrow.counterclockwise.circle")
                }
            }
            .padding([.top,.bottom])
        }
    }
}

#Preview {
    ControlPanel()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
