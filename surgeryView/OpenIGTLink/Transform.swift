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
        guard data.count == messageSize else {return nil}
        var offset = 0
        let offsetAmount = MemoryLayout<UInt32>.size
        
        let a0 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let b0 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let c0 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let a1 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let b1 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let c1 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let a2 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let b2 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let c2 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let a3 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let b3 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        let c3 = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }))
        offset += offsetAmount
        
        return TransformMessage(transform: simd_float4x4(columns: (simd_float4(a0, b0, c0, 0), simd_float4(a1, b1, c1, 0), simd_float4(a2, b2, c2, 0), simd_float4(a3, b3, c3, 1))))
    }


}
