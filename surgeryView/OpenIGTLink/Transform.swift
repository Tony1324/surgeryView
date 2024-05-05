//
//  Transform.swift
//  surgeryView
//
//  Created by Tony Zhang on 5/4/24.
//

import Foundation
import RealityKit

struct TransformMessage {
    var transform: simd_float4x4

    func encode() -> Data{
        var data = Data()
        withUnsafeBytes(of: transform.columns.0.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.0.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.0.z) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.0.w) { data.append(contentsOf: $0 )}

        withUnsafeBytes(of: transform.columns.1.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.1.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.1.z) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.1.w) { data.append(contentsOf: $0 )}

        withUnsafeBytes(of: transform.columns.2.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.2.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.2.z) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.2.w) { data.append(contentsOf: $0 )}

        withUnsafeBytes(of: transform.columns.3.x) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.3.y) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.3.z) { data.append(contentsOf: $0 )}
        withUnsafeBytes(of: transform.columns.3.w) { data.append(contentsOf: $0 )}
        return data
    }


}
