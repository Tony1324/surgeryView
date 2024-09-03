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
    @State var base: Entity = Entity()
    var update: ((RealityViewContent) -> ())?
    
    @State var baseRotation: Float = 0
    @State var dragStartLocation3d: Transform? = nil
    
    var body: some View {
        RealityView { content, attachments in
            
            addBase(content: content, attachments: attachments)
            if !modelData.minimalUI {
                base.position = [0, -0.80, 0]
            }
            
            let originAnchor = Entity()
            
            originAnchor.name = "origin"
            originAnchor.scale = modelData.originTransform.scale
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
            if let originAnchor = base.findEntity(named: "origin"){
                
                //add and delete entities in sync with modelData
                for entity in modelData.models + modelData.imageSlices {
                    if originAnchor.children.contains(entity) {
                        continue
                    }else{
                        addEntity(content: content, entity: entity)
                        positionModels(content: content, attachment: attachments)
                    }
                }
                for entity in originAnchor.children.reversed(){
                    if entity.name == "pointer" {
                        continue
                    }
                    if !(modelData.models + modelData.imageSlices).contains(entity){
                        originAnchor.removeChild(entity)
                        positionModels(content: content, attachment: attachments)
                    }
                }
                
                originAnchor.transform.scale = modelData.originTransform.scale
                
                let animationDefinition = FromToByAnimation(from: base.transform, to: Transform(rotation: modelData.originTransform.rotation), duration: 0.3, timing: .easeOut, bindTarget: .transform)
                if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
                    base.playAnimation(animationResource)
                }

                base.findEntity(named: "rotate")?.transform.rotation = .init(angle: baseRotation, axis: [0,1,0]) * .init(angle: Float.pi/2, axis: [1, 0, 0])
                
                if let pointer = originAnchor.findEntity(named: "pointer") {
                    pointer.setScale([1,1,1], relativeTo: nil)
                    let animationDefinition = FromToByAnimation(from: pointer.transform, to: Transform(scale: pointer.scale, rotation: pointer.transform.rotation, translation: modelData.pointerTransform.translation), duration: 0.1, timing: .linear, bindTarget: .transform)
                    if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
                        pointer.playAnimation(animationResource)
                    }
                    pointer.isEnabled = modelData.pointerIsVisibile
                }
                
                for slice in modelData.imageSlices {
                    slice.isEnabled = modelData.slicesIsVisible
                }
            }
            //allows parent views to also respond to updates
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
            
            Attachment(id: "loading") {
                VStack{
                    if(modelData.models.count + modelData.imageSlices.count == 0){
                        ProgressView("Waiting for content...")
                            .padding(30)
                            .glassBackgroundEffect()
                            .font(.largeTitle)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut)
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
                    if modelData.image != nil {
                        if entity.name == "axial-image" {
                            entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D([0,translation.y,0])), relativeTo: entity.parent)
                            modelData.updateAxialSlice(position: entity.position.y)
                            modelData.sendSlicePosition(name: "AXIAL", pos: entity.position.y)
                            return
                        } else if entity.name == "coronal-image"{
                            entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D([0,0,translation.z])), relativeTo: entity.parent)
                            modelData.updateCoronalSlice(position: entity.position.z)
                            modelData.sendSlicePosition(name: "CORONAL", pos: entity.position.z)
                            return
                        } else if entity.name == "sagittal-image"{
                            entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D([translation.x,0,0])), relativeTo: entity.parent)
                            modelData.updateSagittalSlice(position: entity.position.x)
                            modelData.sendSlicePosition(name: "SAGITTAL", pos: -entity.position.x)
                            return
                        }
                    }
                    if !modelData.minimalUI {
                        entity.move(to: dragStartLocation3d!.whenTranslatedBy(vector: Vector3D(translation)), relativeTo: entity.parent, duration: 0.1)
                    }
                })
                .onEnded({ _ in
                    dragStartLocation3d = nil
                })
        )
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded({ value in
                    guard modelData.models.contains(value.entity) else {return}
                    modelData.sendEntity(entity: value.entity)
                })
        )
    }
    
    func addEntity(content: RealityViewContent ,entity: Entity){
        if let originAnchor = base.findEntity(named: "origin") {
            entity.components.set(InputTargetComponent())
            entity.components.set(HoverEffectComponent())
            originAnchor.addChild(entity)
        }
    }
    
    func addBase(content: RealityViewContent, attachments: RealityViewAttachments) {
        if !modelData.minimalUI {
            base = ModelEntity(mesh: .generateCylinder(height: 0.02, radius: 0.2), materials: [SimpleMaterial.init(color: .black, isMetallic: false)])
        }
        base.name = "base"
        base.components.set(GroundingShadowComponent(castsShadow: true))
        content.add(base)
        if !modelData.minimalUI {
            if let panel = attachments.entity(for: "controls") {
                panel.name = "controls"
                panel.move(to: Transform(translation: [-0.5, 0.2, 0]), relativeTo: base)
                panel.transform.rotation = .init(angle: Float.pi/8, axis: [0, 1, 0])
                base.addChild(panel)
            }
            if let rotation = attachments.entity(for: "rotate") {
                rotation.name = "rotate"
                rotation.transform.rotation = .init(angle: Float.pi/2, axis: [1, 0, 0])
                base.addChild(rotation)
            }
        } else {
            if let loading = attachments.entity(for: "loading"){
                loading.name = "loading"
                content.add(loading)
            }
        }
    }
    
    func positionModels(content: RealityViewContent, attachment: RealityViewAttachments){
        if let originAnchor = base.findEntity(named: "origin"){
            var centers: SIMD3<Float> = [0,0,0]
            
            centers = originAnchor.visualBounds(relativeTo: base).center - originAnchor.position
            let animationDefinition = FromToByAnimation(from: originAnchor.transform, to: Transform(scale: originAnchor.scale, rotation: originAnchor.orientation, translation: [0,0,0] - centers), duration: 0.3, timing: .easeOut, bindTarget: .transform)
            if let animationResource = try? AnimationResource.generate(with: animationDefinition) {
                originAnchor.playAnimation(animationResource)
            }
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
