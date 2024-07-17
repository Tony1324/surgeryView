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
        if let originAnchor = content.entities.first?.findEntity(named: "origin") {
            entity.components.set(InputTargetComponent())
            entity.components.set(HoverEffectComponent())
            entity.generateCollisionShapes(recursive: true)
//            var textLabel = ModelEntity(mesh: MeshResource.generateText("untitled entity"), materials: [SimpleMaterial(color: .white, isMetallic: false)])
            originAnchor.addChild(entity)
//            entity.addChild(textLabel)
//            let bounds = entity.visualBounds(relativeTo: entity)
//            var pos = entity.convert(position: bounds.center, to: nil)
//            pos.z = entity.convert(position:bounds.min, to: nil).z + 0.01
//            textLabel.move(to: Transform(scale: [0.001, 0.001, 0.001],translation: pos), relativeTo: nil)
        }
    }
    
    func addBase(content: RealityViewContent, attachments: RealityViewAttachments) -> ModelEntity {
        let base = ModelEntity(mesh: .generateCylinder(height: 0.02, radius: 0.2), materials: [SimpleMaterial.init(color: .darkGray, isMetallic: false)])
        base.name = "base"
        base.components.set(InputTargetComponent())
        base.generateCollisionShapes(recursive: true)
        content.add(base)
        if let panel = attachments.entity(for: "controls") {
            panel.name = "controls"
            panel.move(to: Transform(translation: [-0.5, 0.2, 0]), relativeTo: base)
            panel.transform.rotation = .init(angle: Float.pi/8, axis: [0, 1, 0])
            base.addChild(panel)
        }
        
        if let toolbar = attachments.entity(for: "toolbar") {
            toolbar.name = "toolbar"
            toolbar.move(to: Transform(translation: [0, -0.05, 0.25]), relativeTo: base)
            toolbar.move(to: Transform(translation: [0, -0.05, 0.25]), relativeTo: base)
            toolbar.transform.rotation = .init(angle: -Float.pi/8, axis: [1, 0, 0])
            base.addChild(toolbar)
        }
        if let rotation = attachments.entity(for: "rotate") {
            rotation.name = "rotate"
            rotation.transform.rotation = .init(angle: Float.pi/2, axis: [1, 0, 0])
            base.addChild(rotation)
        }
        return base
    }
    
    func positionModels(content: RealityViewContent, attachment: RealityViewAttachments){
        if let base = content.entities.first{
            if let originAnchor = base.findEntity(named: "origin"){
                var centers: SIMD3<Float> = [0,0,0]
                var lowestY: Float = 0

                for entity in modelData.models + modelData.imageSlices{
                    guard entity.name != "base" else {continue}
                    guard entity.name != "pointer" else {continue}
                    let bounds = entity.visualBounds(relativeTo: base)
                    centers = centers + (bounds.center - entity.convert(position: entity.position, to: base)) / max((Float(originAnchor.children.count - 1)),1)
                    lowestY = min(lowestY, (bounds.min.y - entity.convert(position: entity.position, to: base).y))
                }

                centers.y = lowestY - 0.05
                originAnchor.position = [0,0,0] - centers

            }
        }
    }
    
    @State var baseRotation: Float = 0
    @State var dragStartLocation3d: Transform? = nil
    
    var body: some View {
        RealityView { content, attachments in
            
            let base = addBase(content: content, attachments: attachments)
            base.position = [0, 1, -1.5]
            
            let originAnchor = Entity()
            
            originAnchor.name = "origin"
            originAnchor.transform = modelData.originTransform
            base.addChild(originAnchor)
            
            let pointer = ModelEntity(mesh: .generateSphere(radius: 0.005),materials: [SimpleMaterial(color: .red.withAlphaComponent(1), isMetallic: false)])
            pointer.name = "pointer"
            pointer.transform = modelData.pointerTransform
            originAnchor.addChild(pointer)
            pointer.setScale([1,1,1], relativeTo: nil)

            for entity in (modelData.models + modelData.imageSlices) {
                addEntity(content: content, entity: entity)
            }




        } update: { content, attachments in
            if let originAnchor = content.entities.first?.findEntity(named: "origin"){
                for entity in modelData.models + modelData.imageSlices {
                    if originAnchor.children.contains(entity) {
                        continue
                    }else{
                        addEntity(content: content, entity: entity)
                    }
                }
                for entity in originAnchor.children.reversed(){
                    if entity.name == "pointer" {
                        continue
                    }
                    if !(modelData.models + modelData.imageSlices).contains(entity){
                        originAnchor.removeChild(entity)
                    }
                    if (modelData.selectedEntity == entity || modelData.selectedEntity == nil) {
                        entity.components.set(OpacityComponent(opacity: 1))
                    } else {
                        entity.components.set(OpacityComponent(opacity: 0.2))
                    }
                }
                originAnchor.transform.scale = modelData.originTransform.scale
                originAnchor.transform.rotation = .init(angle: baseRotation, axis: [0,1,0]) * modelData.originTransform.rotation
                content.entities.first?.findEntity(named: "rotate")?.transform.rotation = .init(angle: baseRotation, axis: [0,1,0]) * .init(angle: Float.pi/2, axis: [1, 0, 0])
                if let pointer = originAnchor.findEntity(named: "pointer") {
                    pointer.move(to: Transform(scale: pointer.transform.scale, translation: modelData.pointerTransform.translation), relativeTo: originAnchor)
                    pointer.setScale([1,1,1], relativeTo: nil)
                }
                print(originAnchor.findEntity(named: "pointer"))
            }
            positionModels(content: content, attachment: attachments)
            if let update {
                update(content)
            }
        } attachments: {
            
            Attachment(id: "rotate") {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 750, weight: .ultraLight))
                    .opacity(0.5)
                    .gesture(
                    DragGesture()
                        .onChanged({ value in
                            self.baseRotation += Float(value.velocity.width)/3000
                        }))
            }
            
            Attachment(id: "controls") {
                ControlPanel()
                    .environment(modelData)
                    .frame(width: 350, height: 500)
            }
            
            Attachment(id: "toolbar") {
                ToolbarView()
                    .environment(modelData)
            }
            
        }
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged({ value in

                    let entity = value.entity
                    if dragStartLocation3d == nil {
                        dragStartLocation3d = entity.transform
                    }

                    let translation = value.convert(value.translation3D, from: .local, to: entity.parent!)
                    if let image = modelData.image {
                        if entity.name == "axial-image" {
                            entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D([0,translation.y,0])), relativeTo: entity.parent)
                            modelData.updateAxialSlice(position: entity.position.y)
                            return
                        } else if entity.name == "coronal-image"{
                            entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D([0,0,translation.z])), relativeTo: entity.parent)
                            modelData.updateCoronalSlice(position: entity.position.z)
                            return
                        } else if entity.name == "sagittal-image"{
                            entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D([translation.x,0,0])), relativeTo: entity.parent)
                            modelData.updateSagittalSlice(position: entity.position.x)
                            return
                        }
                    }
                    entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D(translation)), relativeTo: entity.parent, duration: 0.1)
                })
                .onEnded({ _ in
                    dragStartLocation3d = nil
                })
        )
//        .gesture(
//            RotateGesture3D()
//                .targetedToAnyEntity()
//                .onChanged({ value in
//                    let entity = value.entity
//                    let rot = value.rotation.
//
//                    entity.transform.rotation = entity.parent?.convert(transform: Transform(rotation: .init(ix: Float(-rot.x), iy: Float(rot.y), iz: Float(-rot.z), r: Float(rot.w))), from: nil).rotation ?? .init(ix: Float(-rot.x), iy: Float(rot.y), iz: Float(-rot.z), r: Float(rot.w))
//                    let eulers = value.rotation.eulerAngles(order: .xyz)
//                    let rotTransform = Transform(rotation: .)
//                    entity.transform.rotation = .init(ix: Float(rot.x), iy: Float(rot.y), iz: Float(rot.z), r: Float(rot.w))
//                }))

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
