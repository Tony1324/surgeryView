//
//  ModelManager.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/18/24.
//  Declaratively control a realityKit view

import SwiftUI
import RealityKit

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
            print(modelData.models.count)
        }
    }
    
    @State var dragStartLocation3d: Transform? = nil
    
    var body: some View {
        ZStack(alignment: .leading) {
            RealityView { content in

                let originAnchor = AnchorEntity(world:.zero)
                originAnchor.position = [0, 1, -1.5]
                originAnchor.scale = [0.1, 0.1, 0.1]
                originAnchor.setOrientation(simd_quatf.init(angle: -Float.pi/2, axis: [1, 0, 0]), relativeTo: nil)
                originAnchor.name = "origin"
                let dragBase = ModelEntity(mesh: .generateCylinder(height: 0.4, radius: 3), materials: [SimpleMaterial.init(color: .darkGray, isMetallic: true)])
                dragBase.position = [0, 0, -5]
                dragBase.name = "base"
                dragBase.setOrientation(simd_quatf.init(angle: Float.pi/2, axis: [1, 0, 0]), relativeTo: nil)
                content.add(originAnchor)
                
                addEntity(content: content, entity: dragBase)

                for entity in modelData.models {
                    addEntity(content: content, entity: entity)
                }
            } update: { content in
                if let originAnchor = content.entities.first{
                    for entity in modelData.models {
                        if originAnchor.children.contains(entity) {
                            continue
                        }else{
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
                        
                        let entity = value.entity
                        if entity.name == "base" {
                            if dragStartLocation3d == nil {
                                dragStartLocation3d = entity.parent!.transform
                            }
                            let translation = value.convert(value.translation3D, from: .local, to: .scene)
                            entity.parent?.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D(translation)), relativeTo: nil, duration: 0.1)

                            return
                        }
                        
                        if dragStartLocation3d == nil {
                            dragStartLocation3d = entity.transform
                        }
                        
                        let translation = value.convert(value.translation3D, from: .local, to: entity.parent!)
                        
                        entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D(translation)), relativeTo: entity.parent, duration: 0.1)
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
