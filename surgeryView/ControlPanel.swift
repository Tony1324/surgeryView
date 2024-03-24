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
            VStack{
                List{
                    Section ("Models Visibility"){
                        ForEach(modelData.models){ entity in
                            Toggle(isOn: Binding(get: {
                                return entity.isEnabled
                            }, set: { value in
                                entity.isEnabled = value

                            })) {
                                Text("Toggle \(entity.name.isEmpty ? "Unnamed Object" : entity.name)")
                            }

                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}

#Preview {
    ControlPanel()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
