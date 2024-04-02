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
    @Environment(ModelData.self) var modelData
    var update: ((RealityViewContent) -> ())?
    
    func addEntity(content: RealityViewContent ,entity: Entity){
        if let originAnchor = content.entities.first {
            entity.components.set(InputTargetComponent())
            entity.components.set(HoverEffectComponent())
            entity.generateCollisionShapes(recursive: true)
            originAnchor.addChild(entity)
        }
    }
    
    @State var dragStartLocation3d: Transform? = nil
    
    var body: some View {
        ZStack(alignment: .leading) {
            RealityView { content in

                let originAnchor = AnchorEntity(world:.zero)
                originAnchor.position = [0, 2, -2] 
                originAnchor.name = "origin"
                content.add(originAnchor)
                for entity in modelData.models {
//                    let objectAnchor = Entity()
//                    objectAnchor.addChild(entity)
//                    originAnchor.addChild(objectAnchor)
                    addEntity(content: content, entity: entity)
                }
            } update: { content in
                if let originAnchor = content.entities.first{
                    for entity in modelData.models {
                        if originAnchor.children.contains(entity) {
                            continue
                        }else{
                            //                        let objectAnchor = Entity()
                            //                        objectAnchor.addChild(entity)
                            addEntity(content: content, entity: entity)
                        }
                    }
                    for entity in originAnchor.children {
                        if !modelData.models.contains(entity) {
                            content.remove(entity)
                        }
                    }
                }
                if let update {
                    update(content)
                }
            }
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged({ value in
                        if dragStartLocation3d == nil {
                            dragStartLocation3d = value.entity.transform
                        }
                        let translation = value.convert(value.translation3D, from: .local, to: .scene)
                        value.entity.transform = dragStartLocation3d!.whenTranslatedBy(vector: Vector3D(translation))
                    })
                    .onEnded({ _ in
                        dragStartLocation3d = nil
                    })
            )

        }

    }
}

extension Transform {
        func whenTranslatedBy (vector: Vector3D) -> Transform {
            // Turn the vector translation into a transformation
            let movement = Transform(translation: simd_float3(vector.vector))
    
            // Calculate the new transformation by matrix multiplication
            let result = Transform(matrix: (movement.matrix * self.matrix))

            return result
        }
    }

#Preview {
    ModelManager()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
