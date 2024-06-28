//
//  Image.swift
//  surgeryView
//
//  Created by BreastCAD on 6/11/24.
//

import Foundation
import RealityKit
import CoreGraphics

struct ImageMessage: OpenIGTDecodable {
 
    let v: UInt16
    let num_components: UInt8
    let scalar_type: UInt8 //(2:int8 3:uint8 4:int16 5:uint16 6:int32 7:uint32 10:float32 11:float64)
    let endianness: UInt8
    let image_coordinate: UInt8
    let size: SIMD3<UInt16>
    let traverse_i: SIMD3<Float32>
    let traverse_j: SIMD3<Float32>
    let normal: SIMD3<Float32>
    let position: SIMD3<Float32>
    let subvolume_index: SIMD3<UInt16>
    let subvolume_size: SIMD3<UInt16>
    var image_data: Data
    
    var fullHeight: Float {
        Float(size.z) * Float(normal.z)
    }
    
    static func decode(_ data: Data) -> ImageMessage? {
        let data = DataReader(data)
        
        guard let v: UInt16 = data.readInt() else {return nil}
        guard let num_components: UInt8 = data.readInt() else {return nil}
        guard let scalar_type: UInt8 = data.readInt() else {return nil}
        guard let endianness: UInt8 = data.readInt() else {return nil}
        guard let image_coordinate: UInt8 = data.readInt() else {return nil}
        guard let size: SIMD3<UInt16> = readIndex() else {return nil}
        guard let traverse_i: SIMD3<Float32> = readPosition() else {return nil}
        guard let traverse_j: SIMD3<Float32> = readPosition() else {return nil}
        guard let normal: SIMD3<Float32> = readPosition() else {return nil}
        guard let position: SIMD3<Float32> = readPosition() else {return nil}
        guard let subvolume_index: SIMD3<UInt16> = readIndex() else {return nil}
        guard let subvolume_size: SIMD3<UInt16> = readIndex() else {return nil}
        let image_data: Data = data.remainingData()
        
        func readPosition() -> SIMD3<Float32>? {
            guard let x = data.readFloat() else {return nil}
            guard let y = data.readFloat() else {return nil}
            guard let z = data.readFloat() else {return nil}
            return [x,y,z]
        }
        
        func readIndex() -> SIMD3<UInt16>? {
            guard let x: UInt16 = data.readInt() else {return nil}
            guard let y: UInt16 = data.readInt() else {return nil}
            guard let z: UInt16 = data.readInt() else {return nil}
            return [x,y,z]
        }
        
        return ImageMessage(v: v, num_components: num_components, scalar_type: scalar_type, endianness: endianness, image_coordinate: image_coordinate, size: size, traverse_i: traverse_i, traverse_j: traverse_j, normal: normal, position: position, subvolume_index: subvolume_index, subvolume_size: subvolume_size, image_data: image_data)
        
    }
    
    func scalarSize() -> Int {
        //(2:int8 3:uint8 4:int16 5:uint16 6:int32 7:uint32 10:float32 11:float64)
        return switch scalar_type {
        case 2: MemoryLayout<Int8>.size
        case 3: MemoryLayout<UInt8>.size
        case 4: MemoryLayout<Int16>.size
        case 5: MemoryLayout<UInt16>.size
        case 6: MemoryLayout<Int32>.size
        case 7: MemoryLayout<UInt32>.size
        case 10: MemoryLayout<Float32>.size
        case 11: MemoryLayout<Float64>.size
        default: -1
        }
    }
    
    func createImage(position: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bytePosition = Int(size.x)*Int(size.y)*scalarSize()*Int(num_components)*position
        let byteEndPosition = Int(size.x)*Int(size.y)*scalarSize()*Int(num_components)*(position + 1)
        let rawData = image_data.subdata(in: image_data.startIndex + bytePosition ..< image_data.startIndex + byteEndPosition)
        var data = Data()
        for i in stride(from: rawData.startIndex, to: rawData.endIndex, by: scalarSize()) {
            let pixel = Int(Int32(littleEndian: rawData.subdata(in: i..<i + MemoryLayout<Int32>.size).withUnsafeBytes{$0.load(as: Int32.self)}) )
            let byte = mapColorRange(num: pixel, low: -1000, high: 1000)
            data.append(byte)
            data.append(byte)
            data.append(byte)
            data.append(255)
        }
        
        guard let providerRef = CGDataProvider(data: data as CFData) else {return nil}
        guard let image = CGImage(width: Int(size.x), height: Int(size.y), bitsPerComponent: scalarSize() * 8 / 4, bitsPerPixel: scalarSize()*Int(num_components) * 8, bytesPerRow: Int(size.x)*scalarSize()*Int(num_components), space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {return nil}
        
        //although image is grayscale, scalar pixels get colored as red, so we have to convert to full rgb, but with r,g, and b being the same values
        return image
    }
    
    func mapColorRange(num: Int, low: Int, high: Int) -> UInt8 {
        guard low < high else { return 0 }
        let clampedNum = max(min(num, high), low)
        
        var normalized = Float(clampedNum - low) / Float(high - low)

        return UInt8(normalized * 255)
    }
}
