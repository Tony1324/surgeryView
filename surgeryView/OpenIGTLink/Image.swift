//
//  Image.swift
//  surgeryView
//
//  Created by BreastCAD on 6/11/24.
//

import Foundation
import RealityKit
import CoreGraphics
import Metal

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
        let bytePosition = Int(size.x)*Int(size.y)*4*Int(num_components)*position
        let byteEndPosition = Int(size.x)*Int(size.y)*4*Int(num_components)*(position + 1)
        let rawData = axial_transposed_image.subdata(in: axial_transposed_image.startIndex + bytePosition ..< axial_transposed_image.startIndex + byteEndPosition)
        guard let providerRef = CGDataProvider(data: rawData as CFData) else {return nil}
        guard let image = CGImage(width: Int(size.x), height: Int(size.y), bitsPerComponent: 4 * 8 / 4, bitsPerPixel: 4*Int(num_components) * 8, bytesPerRow: Int(size.x)*4*Int(num_components), space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {return nil}
        return image
    }
    
    func createCoronalImage(position: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bytePosition = Int(size.x)*Int(size.z)*4*Int(num_components)*position
        let byteEndPosition = Int(size.x)*Int(size.z)*4*Int(num_components)*(position + 1)
        let rawData = coronal_transposed_image.subdata(in: coronal_transposed_image.startIndex + bytePosition ..< coronal_transposed_image.startIndex + byteEndPosition)
        guard let providerRef = CGDataProvider(data: rawData as CFData) else {return nil}
        guard let image = CGImage(width: Int(size.x), height: Int(size.z), bitsPerComponent: 4 * 8 / 4, bitsPerPixel: 4*Int(num_components) * 8, bytesPerRow: Int(size.x)*4*Int(num_components), space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {return nil}
        return image
    }
    
    func createSagittalImage(position: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bytePosition = Int(size.y)*Int(size.z)*4*Int(num_components)*position
        let byteEndPosition = Int(size.y)*Int(size.z)*4*Int(num_components)*(position + 1)
        let rawData = sagittal_transposed_image.subdata(in: sagittal_transposed_image.startIndex + bytePosition ..< sagittal_transposed_image.startIndex + byteEndPosition)
        guard let providerRef = CGDataProvider(data: rawData as CFData) else {return nil}
        guard let image = CGImage(width: Int(size.z), height: Int(size.y), bitsPerComponent: 8, bitsPerPixel: 4*Int(num_components) * 8, bytesPerRow: Int(size.z)*4*Int(num_components), space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {return nil}
        return image
    }
//    
//    mutating func setImageData() async {
//        let images = await scaleImageData()
//        axial_transposed_image = images.0
//        coronal_transposed_image = images.1
//        sagittal_transposed_image = images.2
//    }
//    
    mutating func setImageData(){
        let size = SIMD3<Int>(Int(size.x), Int(size.y), Int(size.z))

        let count = size.x*size.y*size.z * 4

        image_data.withUnsafeBytes { pointer in
            
            //3 steps: 
            //1) regularize all image scalar types into uint8 with colors 0-255
            //2) convert to rgb data, but still gray (duplicate each value 3 times and add alpha)
            //3) transpose into axial, coronal, and saggital
            
            
            let adjustScale: MTLFunction?
            guard let device = MTLCreateSystemDefaultDevice(),
                  let library = device.makeDefaultLibrary(),
                  let scalingCommandQueue = device.makeCommandQueue(),
                  let scalingCommandBuffer = scalingCommandQueue.makeCommandBuffer(),
                  let scalingEncoder = scalingCommandBuffer.makeComputeCommandEncoder()
            else {return}
            
            
            switch scalar_type {
            case 2: adjustScale = library.makeFunction(name: "adjustSizeInt8")
            case 3: adjustScale = library.makeFunction(name: "adjustSizeUint8")
            case 4: adjustScale = library.makeFunction(name: "adjustSizeInt16")
            case 5: adjustScale = library.makeFunction(name: "adjustSizeUint16")
            case 6: adjustScale = library.makeFunction(name: "adjustSizeInt32")
            case 7: adjustScale = library.makeFunction(name: "adjustSizeUint32")
            case 10: adjustScale = library.makeFunction(name: "adjustSizeFloat32")
            case 11: adjustScale = library.makeFunction(name: "adjustSizeFloat64")
            default:
                print("Error: Unsupported scalar type \(scalar_type)")
                adjustScale = nil
            }
            
            guard let adjustScale = adjustScale,
                  let scalePipelineState = try? device.makeComputePipelineState(function: adjustScale),
                  let imagePointer = pointer.baseAddress
            else {return}
            
            let imageDataBuffer = device.makeBuffer(bytes: imagePointer, length: image_data.count)
            let scaledDataBuffer = device.makeBuffer(length: size.x*size.y*size.z)

            scalingEncoder.setComputePipelineState(scalePipelineState)
            scalingEncoder.setBuffer(imageDataBuffer, offset: 0, index: 0)
            scalingEncoder.setBuffer(scaledDataBuffer, offset: 0, index: 1)
            
            withUnsafeBytes(of: Int(-1000)) { pointer in
                scalingEncoder.setBytes(pointer.baseAddress!, length: MemoryLayout<Int>.stride, index: 2)
            }
            withUnsafeBytes(of: Int(1000)) { pointer in
                scalingEncoder.setBytes(pointer.baseAddress!, length: MemoryLayout<Int>.stride, index: 3)
            }
            
            let threadGroupSize = MTLSize(width: scalePipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            let scalingThreadGroups = MTLSize(width: (image_data.count + scalePipelineState.maxTotalThreadsPerThreadgroup) / scalePipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            
            scalingEncoder.dispatchThreadgroups(scalingThreadGroups, threadsPerThreadgroup: threadGroupSize)
            scalingEncoder.endEncoding()
            scalingCommandBuffer.commit()
            scalingCommandBuffer.waitUntilCompleted()
            
            guard let grayscaleToRGB = library.makeFunction(name: "grayscaleToRGBA"),
                  let rgbCommandQueue = device.makeCommandQueue(),
                  let rgbPipelineState = try? device.makeComputePipelineState(function: grayscaleToRGB),
                  let rgbCommandBuffer = rgbCommandQueue.makeCommandBuffer(),
                  let rgbEncoder = rgbCommandBuffer.makeComputeCommandEncoder()
            else {return}
            
            let rgbDataBuffer = device.makeBuffer(length: count)
            rgbEncoder.setComputePipelineState(rgbPipelineState)
            rgbEncoder.setBuffer(scaledDataBuffer, offset: 0, index: 0)
            rgbEncoder.setBuffer(rgbDataBuffer, offset: 0, index: 1)
            
            let rgbThreadGroups = MTLSize(width: (size.x*size.y*size.z + threadGroupSize.width) / threadGroupSize.width, height: 1, depth: 1)
            rgbEncoder.dispatchThreadgroups(rgbThreadGroups, threadsPerThreadgroup: threadGroupSize)
            rgbEncoder.endEncoding()
            rgbCommandBuffer.commit()
            rgbCommandBuffer.waitUntilCompleted()
            
            guard let transpose = library.makeFunction(name: "transposeAll"),
                  let transposeCommandQueue = device.makeCommandQueue(),
                  let transposePipelineState = try? device.makeComputePipelineState(function: transpose),
                  let transposeCommandBuffer = transposeCommandQueue.makeCommandBuffer(),
                  let transposeEncoder = transposeCommandBuffer.makeComputeCommandEncoder()
            else {return}
            
            let axialDataBuffer = device.makeBuffer(length: count)
            let coronalDataBuffer = device.makeBuffer(length: count)
            let sagittalDataBuffer = device.makeBuffer(length: count)
            
            transposeEncoder.setComputePipelineState(transposePipelineState)
            transposeEncoder.setBuffer(rgbDataBuffer, offset: 0, index: 0)
            transposeEncoder.setBuffer(axialDataBuffer, offset: 0, index: 1)
            transposeEncoder.setBuffer(coronalDataBuffer, offset: 0, index: 2)
            transposeEncoder.setBuffer(sagittalDataBuffer, offset: 0, index: 3)
            
            withUnsafeBytes(of: size.x) { pointer in
                guard let address = pointer.baseAddress else {return}
                transposeEncoder.setBytes(address, length: MemoryLayout<Int>.stride, index: 4)
            }
            
            withUnsafeBytes(of: size.y) { pointer in
                guard let address = pointer.baseAddress else {return}
                transposeEncoder.setBytes(address, length: MemoryLayout<Int>.stride, index: 5)
            }
            
            withUnsafeBytes(of: size.z) { pointer in
                guard let address = pointer.baseAddress else {return}
                transposeEncoder.setBytes(address, length: MemoryLayout<Int>.stride, index: 6)
            }
            
            withUnsafeBytes(of: alt_mode) { pointer in
                guard let address = pointer.baseAddress else {return}
                transposeEncoder.setBytes(address, length: MemoryLayout<Bool>.stride, index: 7)
            }
            
            let transposeThreadGroups = MTLSize(width: (size.x*size.y*size.z + transposePipelineState.maxTotalThreadsPerThreadgroup - 1) / transposePipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            transposeEncoder.dispatchThreadgroups(transposeThreadGroups, threadsPerThreadgroup: threadGroupSize)
            
            transposeEncoder.endEncoding()
            transposeCommandBuffer.commit()
            transposeCommandBuffer.waitUntilCompleted()
            
            if let axialPointer = axialDataBuffer?.contents(),
               let coronalPointer = coronalDataBuffer?.contents(),
               let sagittalPointer = sagittalDataBuffer?.contents() {
                   axial_transposed_image = Data(bytes: axialPointer, count: count)
                   coronal_transposed_image = Data(bytes: coronalPointer, count: count)
                   sagittal_transposed_image = Data(bytes: sagittalPointer, count: count)
            }
        }
    }
}
