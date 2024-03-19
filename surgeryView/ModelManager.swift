//
//  ModelManager.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/18/24.
//  Declaratively control a realityKit view

import SwiftUI
import RealityKit
import RealityKitContent

struct ModelManager: View {
    // custom content handling
    var entities: [Entity]
    var update: ((RealityViewContent) -> ())?
    var body: some View {
        ZStack(alignment: .leading) {
            RealityView { content in
                for entity in entities {
                    content.add(entity)
                }
            } update: { content in
                for entity in entities {
                    if content.entities.contains(entity) {continue}
                    content.add(entity)
                }
                for entity in content.entities {
                    if !entities.contains(entity) {
                        content.remove(entity)
                    }
                }
                if let update {
                    update(content)
                }
            }
            VStack{
                ForEach(entities){ entity in
                    Button {
                        entity.isEnabled.toggle()
                    } label: {
                        Text("Toggle Entity")
                    }

                }
            }
            .frame(width: 200)
            .padding()
            .glassBackgroundEffect()
        }

    }
}

#Preview {
    ModelManager(entities: [ModelEntity(mesh: .generateBox(size: 0.5))])
}
