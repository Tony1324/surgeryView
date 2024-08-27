//
//  DataReader.swift
//  surgeryView
//
//  Created by Tony Zhang on 5/23/24.
//

import Foundation

//helper library for displaying and processing data
class DataReader {
    var data: Data
    init(_ data: Data) {
        self.data = data
    }
    
    //default printing of data only outputs its size, this shows actual content of the data
    func prettyPrint() {
        print("\(data.count) Bytes")
        print(data.map { String(format: "%02x", $0) }.joined(separator: " "))
    }
    
    //generic function allowing for Int32, Int64, UInt, etc
    func readInt<T:FixedWidthInteger>() -> T? {
        if data.count >= MemoryLayout<T>.size {
            let x = T(bigEndian: data.subdata(in: data.startIndex..<data.startIndex + MemoryLayout<T>.size).withUnsafeBytes{$0.load(as: T.self)})
            data.removeFirst(MemoryLayout<T>.size)
            return x
        }
        return nil
    }
    
    func readString(length: Int) -> String? {
        if data.count >= length {
            let str = String(data: data.subdata(in: data.startIndex..<data.startIndex + length), encoding: .ascii)
            data.removeFirst(length)
            return str
        }
        return nil
    }
    
    func readFloat() -> Float32? {
        if data.count >= MemoryLayout<Float32>.size {
            let float = Float32(bitPattern: UInt32(bigEndian: data.subdata(in: data.startIndex..<data.startIndex + MemoryLayout<Float32>.size).withUnsafeBytes { $0.load(as: UInt32.self) }))
            data.removeFirst(MemoryLayout<Float32>.size)
            return float
        }
        return nil
    }
    
    func remainingData() -> Data{
        //when Data is deleted in above functions, it only shifts the start index,
        //while this seems to return the entire Data, it actually successfully removes what was deleted
        data.suffix(from: data.startIndex)
    }
}
