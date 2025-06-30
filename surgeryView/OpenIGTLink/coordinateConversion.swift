//
//  coordinateConversion.swift
//  surgeryView
//
//  Created by BreastCAD on 6/30/25.
//

import simd

// Conversion matrix: RAS → RealityKit
let rasToRKMatrix = float4x4(
    SIMD4<Float>( 1,  0,  0, 0),  // X → X
    SIMD4<Float>( 0,  0, -1, 0),  // Z → Y
    SIMD4<Float>( 0,  1,  0, 0),  // -Y → Z
    SIMD4<Float>( 0,  0,  0, 1)
)

// Inverse matrix: RealityKit → RAS
let rkToRASMatrix = float4x4(
    SIMD4<Float>( 1,  0,  0, 0),
    SIMD4<Float>( 0,  0,  1, 0),
    SIMD4<Float>( 0, -1,  0, 0),
    SIMD4<Float>( 0,  0,  0, 1)
)

// MARK: - Transform Functions

/// Converts a vector from RAS to RealityKit
func rasToRealityKit(_ ras: SIMD3<Float>) -> SIMD3<Float> {
    let rasVec4 = SIMD4<Float>(ras, 1.0)
    let rkVec4 = rasToRKMatrix * rasVec4
    return SIMD3<Float>(rkVec4.x, rkVec4.y, rkVec4.z)
}

/// Converts a vector from RealityKit to RAS
func realityKitToRAS(_ rk: SIMD3<Float>) -> SIMD3<Float> {
    let rkVec4 = SIMD4<Float>(rk, 1.0)
    let rasVec4 = rkToRASMatrix * rkVec4
    return SIMD3<Float>(rasVec4.x, rasVec4.y, rasVec4.z)
}

/// Converts a full 4x4 transform from RAS to RealityKit
func rasToRealityKitTransform(_ rasTransform: float4x4) -> float4x4 {
    return rasToRKMatrix * rasTransform * rkToRASMatrix
}

/// Converts a full 4x4 transform from RealityKit to RAS
func realityKitToRASTransform(_ rkTransform: float4x4) -> float4x4 {
    return rkToRASMatrix * rkTransform * rasToRKMatrix
}
