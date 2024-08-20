//
//  ContentView.swift
//  surgeryViewImageProcessingTest
//
//  Created by Tony Zhang on 8/19/24.
//

import SwiftUI
import Metal

struct ModelData: Observable {
    var image: CGImage?
    var size: SIMD3<Int> = [500, 500, 500]
    init() {
        var rawData = Data(count: size.x*self.size.y*self.size.z*4)
        for x in 0..<size.x*size.y*size.z{
            var num = Int32.random(in: -1000..<(1000))
            rawData.replaceSubrange(x*4..<(x+1)*4, with: Data(bytes: &num, count: 4))
        }

        guard let device = MTLCreateSystemDefaultDevice(),
              let library = device.makeDefaultLibrary(),
              let commandQueue = device.makeCommandQueue(),
              let adjustSizeInt32 = library.makeFunction(name: "adjustSizeInt32"),
              let pipelineStateInt32 = try? device.makeComputePipelineState(function: adjustSizeInt32),
              let grayscaleToRGBA = library.makeFunction(name: "grayscaleToRGBA"),
              let pipelineStateGTR = try? device.makeComputePipelineState(function: grayscaleToRGBA),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {return}
        
        rawData.withUnsafeBytes{ pointer in
            let rawDataBuffer = device.makeBuffer(bytes: pointer.baseAddress!, length: rawData.count)
            let shrunkBuffer = device.makeBuffer(length: rawData.count / 4)
            computeEncoder.setComputePipelineState(pipelineStateInt32)

            computeEncoder.setBuffer(rawDataBuffer, offset: 0, index: 0)
            computeEncoder.setBuffer(shrunkBuffer, offset: 0, index: 1)
            
            
            withUnsafeBytes(of: Int(-1000)) { pointer in
                computeEncoder.setBytes(pointer.baseAddress!, length: MemoryLayout<Int>.stride, index: 2)
            }
            withUnsafeBytes(of: Int(1000)) { pointer in
                computeEncoder.setBytes(pointer.baseAddress!, length: MemoryLayout<Int>.stride, index: 3)
            }
            
            let threadGroupSize = MTLSize(width: pipelineStateGTR.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            let threadGroups = MTLSize(width: (rawData.count + pipelineStateGTR.maxTotalThreadsPerThreadgroup) / pipelineStateGTR.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            
            computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
          
            //print time for operation in console

            computeEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
           
            
            
            guard let newCommandBuffer = commandQueue.makeCommandBuffer(),
                      let newComputeEncoder = newCommandBuffer.makeComputeCommandEncoder() else { return }
                
            // Set up buffers for the second kernel
            let outputBufferRGBA = device.makeBuffer(length: rawData.count, options: [])
            
            // Set up and dispatch the second kernel
            newComputeEncoder.setComputePipelineState(pipelineStateGTR)
            newComputeEncoder.setBuffer(shrunkBuffer, offset: 0, index: 0) // input from first kernel
            newComputeEncoder.setBuffer(outputBufferRGBA, offset: 0, index: 1) // output for second kernel
            
            // Set up thread groups for the second kernel
            let threadGroupsGTR = MTLSize(width: (rawData.count + pipelineStateGTR.maxTotalThreadsPerThreadgroup) / pipelineStateGTR.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
            newComputeEncoder.dispatchThreadgroups(threadGroupsGTR, threadsPerThreadgroup: threadGroupSize)
            
            newComputeEncoder.endEncoding()
            
            // Commit and wait for the second kernel to complete
            newCommandBuffer.commit()
            newCommandBuffer.waitUntilCompleted()
            
            // Retrieve the output data from the second kernel if needed
            let finalOutputPointer = outputBufferRGBA?.contents()
            
            rawData = Data(bytes: finalOutputPointer!, count: rawData.count)
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bytePosition = Int(size.x)*Int(size.z)*0
        let byteEndPosition = Int(size.x)*Int(size.z)*1
        let coronalData = rawData.subdata(in: rawData.startIndex + bytePosition ..< rawData.startIndex + byteEndPosition)
        guard let providerRef = CGDataProvider(data: rawData as CFData) else {return}
        image = CGImage(width: Int(size.x), height: Int(size.z), bitsPerComponent: 8, bitsPerPixel: 8*4, bytesPerRow: Int(size.x)*4, space: colorSpace, bitmapInfo: bitmapInfo, provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
    func prettyPrint(_ data: Data) {
        print("\(data.count) Bytes")
        print(data.map { String(format: "%02x", $0) }.joined(separator: " "))
    }
}

struct ContentView: View {
    @State var modelData = ModelData()
    var body: some View {
        VStack {
            if (modelData.image != nil){
//                Image(modelData.image)
                Image(modelData.image!, scale: 3, orientation: .down, label: Text("image"))
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
