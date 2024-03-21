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

                let originAnchor = Entity()
                originAnchor.name = "origin"
                content.add(originAnchor)
                for entity in entities {
                    let objectAnchor = Entity()
                    objectAnchor.addChild(entity)
                    originAnchor.addChild(objectAnchor)
                }
            } update: { content in
                if let originAnchor = content.entities.first{
                    for entity in entities {
                        if originAnchor.children.contains(where: { $0.children.contains(entity)}) {continue}
                        let objectAnchor = Entity()
                        objectAnchor.addChild(entity)
                        originAnchor.addChild(objectAnchor)
                    }
                    for entity in originAnchor.children {
                        if !originAnchor.children.contains(where: { $0.children.contains(entity)}) {
                            content.remove(entity)
                        }
                    }
                }
                if let update {
                    update(content)
                }
            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onChanged({ value in
                        print("changed")
                        value.entity.removeFromParent()
                    })
                    .onEnded({ value in
                        print("tapped")
                        value.entity.isEnabled.toggle()
                    })
            )
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
    ModelManager(entities: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])])
}
