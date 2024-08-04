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
        guard let image = CGImage(width: Int(size.z), height: Int(size.y), bitsPerComponent: scalarSize() * 8 / 4, bitsPerPixel: scalarSize()*Int(num_components) * 8, bytesPerRow: Int(size.z)*scalarSize()*Int(num_components), space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {return nil}
        
        //although image is grayscale, scalar pixels get colored as red, so we have to convert to full rgb, but with r,g, and b being the same values
        return image
    }
    
    mutating func setImageData() async {
        let images = await scaleImageData()
        axial_transposed_image = images.0
        coronal_transposed_image = images.1
        sagittal_transposed_image = images.2
    }
    
    func scaleImageData() async ->  (Data, Data, Data){
        var axial_transposed_image = Data(count: image_data.count)
        var coronal_transposed_image = Data(count: image_data.count)
        var sagittal_transposed_image = Data(count: image_data.count)
        let size = SIMD3<Int>(Int(size.x), Int(size.y), Int(size.z))
        
        await withTaskGroup(of: (Int, Int, Data, Data, Data).self) { group in
            let concurrentTaskCount = 8
            
            // Calculate chunk size
            let count = Int(size.x) * Int(size.y) * Int(size.z)
            let chunkSize = count / concurrentTaskCount
            
            for chunk in 0..<concurrentTaskCount {
                let startIndex = chunk * chunkSize
                let endIndex = (chunk == concurrentTaskCount - 1) ? count : (chunk + 1) * chunkSize
                let scalarSize = scalarSize()
                // Add task to the group
                let totalSize = (endIndex - startIndex) * scalarSize
                group.addTask {
                    var axial_transposed_image = Data(count: totalSize)
                    var coronal_transposed_image = Data(count: totalSize)
                    var sagittal_transposed_image = Data(count: totalSize)
                    image_data.withUnsafeBytes { rawPointer in
                        let baseAddress = rawPointer.baseAddress!.assumingMemoryBound(to: Int32.self)
                        for _i in startIndex..<endIndex{
                            let axialPos = indexToPos(_i, a: size.x, b: size.y, c: size.z)
                            let axialI = posToIndex([axialPos.x, axialPos.y, axialPos.z])
                            let coronalPos = indexToPos(_i, a: size.x, b: size.z, c: size.y)
                            let coronalI = posToIndex([coronalPos.x, coronalPos.z, coronalPos.y])
                            let sagittalPos = indexToPos(_i, a: size.z, b: size.y, c: size.x)
                            let sagittalI = posToIndex([sagittalPos.z, sagittalPos.y, sagittalPos.x])
                            
                            let pixelA = Int(Int32(littleEndian: baseAddress[axialI]))
                            let byteA = mapColorRange(num: pixelA, low: -1000, high: 1000)
                            let pixelC = Int(Int32(littleEndian: baseAddress[coronalI]))
                            let byteC = mapColorRange(num: pixelC, low: -1000, high: 1000)
                            let pixelS = Int(Int32(littleEndian: baseAddress[sagittalI]))
                            let byteS = mapColorRange(num: pixelS, low: -1000, high: 1000)
                                                    
                            let i = (_i - startIndex) * scalarSize
                            axial_transposed_image[i] = byteA
                            axial_transposed_image[i+1] = byteA
                            axial_transposed_image[i+2] = byteA
                            axial_transposed_image[i+3] = 255
                            coronal_transposed_image[i] = byteC
                            coronal_transposed_image[i+1] = byteC
                            coronal_transposed_image[i+2] = byteC
                            coronal_transposed_image[i+3] = 255
                            sagittal_transposed_image[i] = byteS
                            sagittal_transposed_image[i+1] = byteS
                            sagittal_transposed_image[i+2] = byteS
                            sagittal_transposed_image[i+3] = 255
                        }
                    }
                    return (startIndex, endIndex, axial_transposed_image, coronal_transposed_image, sagittal_transposed_image)
                }
            }
            for await result in group {
                let startIndex = result.0
                let endIndex = result.1
                let range = startIndex * scalarSize() ..< endIndex * scalarSize()
                
                axial_transposed_image.replaceSubrange(range, with: result.2)
                coronal_transposed_image.replaceSubrange(range, with: result.3)
                sagittal_transposed_image.replaceSubrange(range, with: result.4)
            }
                    
            
            // Wait for all tasks to complete
            await group.waitForAll()
        }
        
       
        func indexToPos(_ i:Int, a sizeA: Int, b sizeB: Int, c sizeC: Int) -> SIMD3<Int> {
            let z = i / (sizeA * sizeB)
            let y = (i / sizeA) % (sizeB)
            let x = i % (sizeA)
            return [x,y,z]
        }
        
        func posToIndex(_ pos: SIMD3<Int>) -> Int{
            return alt_mode ? (pos.y * size.x * size.z + pos.z * size.x + pos.x) : (pos.z * size.x * size.y + pos.y * size.x + pos.x)
        }
        
        return (axial_transposed_image, coronal_transposed_image, sagittal_transposed_image)
    }
    
    
    
    func mapColorRange(num: Int, low: Int, high: Int) -> UInt8 {
        guard low < high else { return 0 }
        let clampedNum = max(min(num, high), low)
        
        let normalized = (clampedNum - low) * 255 / (high - low)
        
        return UInt8(normalized)
    }
}
