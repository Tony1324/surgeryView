//
//  Transform.swift
//  surgeryView
//
//  Created by Tony Zhang on 5/4/24.
//

import Foundation
import RealityKit

struct TransformMessage: OpenIGTEncodable{
    var transform: simd_float4x4
    
    static var messageSize = MemoryLayout<Float32>.size * 4 * 3

    func encode() -> Data{
        var data = Data()
        withUnsafeBytes(of: transform.columns.0.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.0.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.0.z) { data.append(contentsOf: $0 )}

        withUnsafeBytes(of: transform.columns.1.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.1.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.1.z) { data.append(contentsOf: $0 )}

        withUnsafeBytes(of: transform.columns.2.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.2.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.2.z) { data.append(contentsOf: $0 )}

        withUnsafeBytes(of: transform.columns.3.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.3.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.3.z) { data.append(contentsOf: $0 )}
        return data
    }
    
    static func decode(_ data: Data) -> TransformMessage?{
        guard data.count >= messageSize else {return nil}
        let data = DataReader(data)
        
        guard let a0 = data.readFloat() else {return nil}
        guard let b0 = data.readFloat() else {return nil}
        guard let c0 = data.readFloat() else {return nil}
        guard let a1 = data.readFloat() else {return nil}
        guard let b1 = data.readFloat() else {return nil}
        guard let c1 = data.readFloat() else {return nil}
        guard let a2 = data.readFloat() else {return nil}
        guard let b2 = data.readFloat() else {return nil}
        guard let c2 = data.readFloat() else {return nil}
        guard let a3 = data.readFloat() else {return nil}
        guard let b3 = data.readFloat() else {return nil}
        guard let c3 = data.readFloat() else {return nil}
        
        return TransformMessage(transform: simd_float4x4(columns: (
            simd_float4(a0, c0, -b0, 0),
            simd_float4(a1, c1, -b1, 0),
            simd_float4(a2, c2, -b2, 0),
            simd_float4(a3, c3, -b3, 1)
        )))
    }
    
    func realityKitTransform() -> Transform {
        return Transform(matrix: transform)
    }


}
