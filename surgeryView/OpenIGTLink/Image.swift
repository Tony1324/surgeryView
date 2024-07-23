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
    var axial_transposed_image: Data = Data()
    var coronal_transposed_image: Data = Data()
    var sagittal_transposed_image: Data = Data()
    var alt_mode = false

    
    var fullHeight: Float {
        Float(size.z) * Float(normal.z)
    }
    var fullWidth: Float {
        Float(size.x) * Float(traverse_i.x)
    }
    var fullLength: Float {
        Float(size.y) * Float(traverse_j.y)
    }

    static func decode(_ data: Data) -> ImageMessage? {
        let data = DataReader(data)
        
        guard let v: UInt16 = data.readInt() else {return nil}
        guard let num_components: UInt8 = data.readInt() else {return nil}
        guard let scalar_type: UInt8 = data.readInt() else {return nil}
        guard let endianness: UInt8 = data.readInt() else {return nil}
        guard let image_coordinate: UInt8 = data.readInt() else {return nil}
        guard var size: SIMD3<UInt16> = readIndex() else {return nil}
        guard let traverse_i: SIMD3<Float32> = readPosition() else {return nil}
        guard var traverse_j: SIMD3<Float32> = readPosition() else {return nil}
        guard var normal: SIMD3<Float32> = readPosition() else {return nil}
        guard var position: SIMD3<Float32> = readPosition() else {return nil}
        guard let subvolume_index: SIMD3<UInt16> = readIndex() else {return nil}
        guard let subvolume_size: SIMD3<UInt16> = readIndex() else {return nil}
        let image_data: Data = data.remainingData()
        
        var alt_mode = false
        if abs(normal.z) <= 0.01 {
            alt_mode = true
            traverse_j.y = normal.y
            normal.z = traverse_j.z
            traverse_j.z = 0
            normal.y = 0
            let _sizey = size.y
            size.y = size.z
            size.z = _sizey
//            let _posy = position.y
//            position.y = position.z
//            position.z = _posy
        }
        
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
        
        return ImageMessage(v: v, num_components: num_components, scalar_type: scalar_type, endianness: endianness, image_coordinate: image_coordinate, size: size, traverse_i: traverse_i, traverse_j: traverse_j, normal: normal, position: position, subvolume_index: subvolume_index, subvolume_size: subvolume_size, image_data: image_data, alt_mode: alt_mode)
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
    
    func createAxialImage(position: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bytePosition = Int(size.x)*Int(size.y)*scalarSize()*Int(num_components)*position
        let byteEndPosition = Int(size.x)*Int(size.y)*scalarSize()*Int(num_components)*(position + 1)
        let rawData = axial_transposed_image.subdata(in: axial_transposed_image.startIndex + bytePosition ..< axial_transposed_image.startIndex + byteEndPosition)
        guard let providerRef = CGDataProvider(data: rawData as CFData) else {return nil}
        guard let image = CGImage(width: Int(size.x), height: Int(size.y), bitsPerComponent: scalarSize() * 8 / 4, bitsPerPixel: scalarSize()*Int(num_components) * 8, bytesPerRow: Int(size.x)*scalarSize()*Int(num_components), space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {return nil}
        return image
    }
    
    func createCoronalImage(position: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bytePosition = Int(size.x)*Int(size.z)*scalarSize()*Int(num_components)*position
        let byteEndPosition = Int(size.x)*Int(size.z)*scalarSize()*Int(num_components)*(position + 1)
        let rawData = coronal_transposed_image.subdata(in: coronal_transposed_image.startIndex + bytePosition ..< coronal_transposed_image.startIndex + byteEndPosition)
        guard let providerRef = CGDataProvider(data: rawData as CFData) else {return nil}
        guard let image = CGImage(width: Int(size.x), height: Int(size.z), bitsPerComponent: scalarSize() * 8 / 4, bitsPerPixel: scalarSize()*Int(num_components) * 8, bytesPerRow: Int(size.x)*scalarSize()*Int(num_components), space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {return nil}
        return image
    }
    
    func createSagittalImage(position: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bytePosition = Int(size.y)*Int(size.z)*scalarSize()*Int(num_components)*position
        let byteEndPosition = Int(size.y)*Int(size.z)*scalarSize()*Int(num_components)*(position + 1)
        let rawData = sagittal_transposed_image.subdata(in: sagittal_transposed_image.startIndex + bytePosition ..< sagittal_transposed_image.startIndex + byteEndPosition)
        guard let providerRef = CGDataProvider(data: rawData as CFData) else {return nil}
        guard let image = CGImage(width: Int(size.y), height: Int(size.z), bitsPerComponent: scalarSize() * 8 / 4, bitsPerPixel: scalarSize()*Int(num_components) * 8, bytesPerRow: Int(size.y)*scalarSize()*Int(num_components), space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {return nil}
        
        //although image is grayscale, scalar pixels get colored as red, so we have to convert to full rgb, but with r,g, and b being the same values
        return image
    }
    
    mutating func scaleImageData(){
        axial_transposed_image = Data(count: image_data.count)
        coronal_transposed_image = Data(count: image_data.count)
        sagittal_transposed_image = Data(count: image_data.count)
        var size = size
        for z in 0..<Int(size.z){
            for y in 0..<Int(size.y) {
                for x in 0..<Int(size.x) {
                    let i = alt_mode ? (y * Int(size.x) * Int(size.z) + z * Int(size.x) + x) * scalarSize() : (z * Int(size.x) * Int(size.y) + y * Int(size.x) + x) * scalarSize()
                    let pixel = Int(Int32(littleEndian: image_data.subdata(in: image_data.startIndex + i ..<  image_data.startIndex + i + MemoryLayout<Int32>.size).withUnsafeBytes{$0.load(as: Int32.self)}) )
                    let byte = mapColorRange(num: pixel, low: -1000, high: 1000)
                    
                    let axialI = (z * Int(size.x) * Int(size.y) + y * Int(size.x) + x) * scalarSize()
                    let coronalI = (y * Int(size.x) * Int(size.z) + z * Int(size.x) + x) * scalarSize()
                    let sagittalI = (x * Int(size.z) * Int(size.y) + z * Int(size.y) + y) * scalarSize()
                    
                    axial_transposed_image[axialI] = byte
                    axial_transposed_image[axialI+1] = byte
                    axial_transposed_image[axialI+2] = byte
                    axial_transposed_image[axialI+3] = 255
                    coronal_transposed_image[coronalI] = byte
                    coronal_transposed_image[coronalI+1] = byte
                    coronal_transposed_image[coronalI+2] = byte
                    coronal_transposed_image[coronalI+3] = 255
                    sagittal_transposed_image[sagittalI] = byte
                    sagittal_transposed_image[sagittalI+1] = byte
                    sagittal_transposed_image[sagittalI+2] = byte
                    sagittal_transposed_image[sagittalI+3] = 255
                }
            }
        }
    }
    
    func mapColorRange(num: Int, low: Int, high: Int) -> UInt8 {
        guard low < high else { return 0 }
        let clampedNum = max(min(num, high), low)
        
        let normalized = Float(clampedNum - low) / Float(high - low)

        return UInt8(normalized * 255)
    }
}
