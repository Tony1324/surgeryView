//
//  DataReader.swift
//  surgeryView
//
//  Created by BreastCAD on 5/23/24.
//

import Foundation

class DataReader {
    var data: Data
    init(data: Data) {
        self.data = data
    }
    func prettyPrint() {
        print("\(data.count) Bytes")
        print(data.map { String(format: "%02x", $0) }.joined(separator: " "))
    }
    func readInt<T:FixedWidthInteger>() -> T? {
        if data.count >= MemoryLayout<T>.size {
            let x = T(bigEndian: data.withUnsafeBytes{$0.load(fromByteOffset: data.startIndex, as: T.self)})
            data.removeFirst(MemoryLayout<T>.size)
            return x
        }
        return nil
    }
    
    func readString(_ length: Int) -> String? {
        if data.count >= length {
            print(data.startIndex)
            let str = String(data: data.subdata(in: data.startIndex..<data.startIndex + length), encoding: .ascii)
            data.removeFirst(length)
            return str
        }
        return nil
    }
    
    func readFloat() -> Float32? {
        if data.count >= MemoryLayout<Float32>.size {
            let float = Float32(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.load(fromByteOffset: data.startIndex, as: UInt32.self) }))
            data.removeFirst(MemoryLayout<Float32>.size)
            return float
        }
        return nil
    }
}
