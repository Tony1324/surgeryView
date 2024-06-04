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
            var textLabel = ModelEntity(mesh: MeshResource.generateText("untitled entity"), materials: [SimpleMaterial(color: .white, isMetallic: false)])
            originAnchor.addChild(entity)
            entity.addChild(textLabel)
            let bounds = entity.visualBounds(relativeTo: entity)
            var pos = entity.convert(position: bounds.center, to: nil)
            pos.z = entity.convert(position:bounds.min, to: nil).z + 0.01
            textLabel.move(to: Transform(scale: [0.001, 0.001, 0.001],translation: pos), relativeTo: nil)
            
            
        }
    }
    
    func addBase(content: RealityViewContent) {
        if let originAnchor = content.entities.first {
            let dragBase = ModelEntity(mesh: .generateCylinder(height: 0.02, radius: 0.2), materials: [SimpleMaterial.init(color: .darkGray, isMetallic: false)])
            dragBase.name = "base"
            addEntity(content: content, entity: dragBase)
            dragBase.move(to: dragBase.convert(transform: Transform(), to: originAnchor), relativeTo: nil)

        }
    }
    
    func positionBase(content: RealityViewContent){
        if let originAnchor = content.entities.first{
            if let base = originAnchor.findEntity(named: "base"){

                var centers: SIMD3<Float> = [0,0,0]
                var lowestZ: Float = 0

                base.transform = Transform()
                base.move(to: base.convert(transform: Transform(), to: originAnchor), relativeTo: nil)

                for entity in originAnchor.children {
                    guard entity.name != "base" else {continue}
                    let bounds = entity.visualBounds(relativeTo: originAnchor)
                    centers = centers + bounds.center /  max((Float(originAnchor.children.count - 1)),1)
                    lowestZ = min(lowestZ, bounds.min.z)
                }

                centers.z = lowestZ - 0.1
//                centers = [0,0,0]
                base.position = centers

            }else {
                addBase(content: content)
                positionBase(content: content)
            }
        }
    }
    
    @State var dragStartLocation3d: Transform? = nil
    
    var body: some View {
        ZStack(alignment: .leading) {
            RealityView { content in

                let originAnchor = AnchorEntity(world:.zero)
                originAnchor.position = [0, 1, -1.5]
                originAnchor.scale = [0.001, 0.001, 0.001] // hardcoded value for now
                originAnchor.setOrientation(simd_quatf.init(angle: Float.pi, axis: [0, 1, 0]), relativeTo: nil)
//                originAnchor.setOrientation(.init(ix: Float.pi/4, iy: 0, iz: -Float.pi/4, r: 0), relativeTo: nil)
                
                originAnchor.name = "origin"
                originAnchor.transform = modelData.originTransform
                content.add(originAnchor)


                for entity in modelData.models {
                    addEntity(content: content, entity: entity)
                }
                
                addBase(content: content)
                
            } update: { content in
                if let originAnchor = content.entities.first{
                    for entity in modelData.models {
                        if originAnchor.children.contains(entity) {
                            continue
                        }else{
                            addEntity(content: content, entity: entity)
                        }
                    }
                    for entity in originAnchor.children.reversed() {
                        if !modelData.models.contains(entity) && entity.name != "base" {
                            originAnchor.removeChild(entity)
                        }
                    }
                    originAnchor.transform = modelData.originTransform
                }
                positionBase(content: content)
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
