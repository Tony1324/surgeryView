//
//  imageprocessing.metal
//  surgeryViewImageProcessingTest
//
//  Created by Tony Zhang on 8/19/24.
//

#include <metal_stdlib>
using namespace metal;


template <typename T>
void adjustSizeGeneric(device const T* inData [[ buffer(0) ]],
                              device uint8_t* outData [[ buffer(1) ]],
                              device const int& lower [[ buffer(2) ]],
                              device const int& upper [[ buffer(3) ]],
                              uint index [[ thread_position_in_grid ]]) {
    // Convert the input value to float
    float value = T(inData[index]);
    float lowerBound = lower;
    float upperBound = upper;

    // Clamp the value within the specified bounds
    if (value < lowerBound) {
        value = lowerBound;
    } else if (value > upperBound) {
        value = upperBound;
    }

    // Normalize the value to a range of 0 to 1
    uint8_t normalized = (value - lowerBound) * 255 / (upperBound - lowerBound);
    
    // Output the scaled value
    outData[index] = normalized;
}

kernel void adjustSizeInt8(device const int8_t* inData [[ buffer(0) ]],
                           device uint8_t* outData [[ buffer(1) ]],
                           device const int& lower [[ buffer(2) ]],
                           device const int& upper [[ buffer(3) ]],
                           uint index [[ thread_position_in_grid ]]) {
    adjustSizeGeneric<int8_t>(inData, outData, lower, upper, index);
}

kernel void adjustSizeUint8(device const uint8_t* inData [[ buffer(0) ]],
                            device uint8_t* outData [[ buffer(1) ]],
                            device const int& lower [[ buffer(2) ]],
                            device const int& upper [[ buffer(3) ]],
                            uint index [[ thread_position_in_grid ]]) {
    adjustSizeGeneric<uint8_t>(inData, outData, lower, upper, index);
}

kernel void adjustSizeInt16(device const int16_t* inData [[ buffer(0) ]],
                            device uint8_t* outData [[ buffer(1) ]],
                            device const int& lower [[ buffer(2) ]],
                            device const int& upper [[ buffer(3) ]],
                            uint index [[ thread_position_in_grid ]]) {
    adjustSizeGeneric<int16_t>(inData, outData, lower, upper, index);
}

kernel void adjustSizeUint16(device const uint16_t* inData [[ buffer(0) ]],
                             device uint8_t* outData [[ buffer(1) ]],
                             device const int& lower [[ buffer(2) ]],
                             device const int& upper [[ buffer(3) ]],
                             uint index [[ thread_position_in_grid ]]) {
    adjustSizeGeneric<uint16_t>(inData, outData, lower, upper, index);
}

kernel void adjustSizeInt32(device const int32_t* inData [[ buffer(0) ]],
                            device uint8_t* outData [[ buffer(1) ]],
                            device const int& lower [[ buffer(2) ]],
                            device const int& upper [[ buffer(3) ]],
                            uint index [[ thread_position_in_grid ]]) {
    adjustSizeGeneric<int32_t>(inData, outData, lower, upper, index);
}

kernel void adjustSizeUint32(device const uint32_t* inData [[ buffer(0) ]],
                             device uint8_t* outData [[ buffer(1) ]],
                             device const int& lower [[ buffer(2) ]],
                             device const int& upper [[ buffer(3) ]],
                             uint index [[ thread_position_in_grid ]]) {
    adjustSizeGeneric<uint32_t>(inData, outData, lower, upper, index);
}

kernel void adjustSizeFloat32(device const float* inData [[ buffer(0) ]],
                              device uint8_t* outData [[ buffer(1) ]],
                              device const int& lower [[ buffer(2) ]],
                              device const int& upper [[ buffer(3) ]],
                              uint index [[ thread_position_in_grid ]]) {
    adjustSizeGeneric<float>(inData, outData, lower, upper, index);
}

kernel void adjustSizeFloat64(device const float* inData [[ buffer(0) ]],
                              device uint8_t* outData [[ buffer(1) ]],
                              device const int& lower [[ buffer(2) ]],
                              device const int& upper [[ buffer(3) ]],
                              uint index [[ thread_position_in_grid ]]) {
    adjustSizeGeneric<float>(inData, outData,lower, upper, index);
}

kernel void grayscaleToRGBA(device const uint8_t* inData [[buffer(0)]],
                            device uint8_t* outData [[buffer(1)]],
                            uint index [[thread_position_in_grid]]) {
    int8_t value = inData [index];
    outData[index*4] = value;
    outData[index*4+1] = value;
    outData[index*4+2] = value;
    outData[index*4+3] = 255;
}



int3 indexToPos(const int i, const int a, const int b, const int c) {
    int z = i / (a * b);
    int y = (i / a) % b;
    int x = i % (a);
    int3 pos = int3(x,y,z);
    return pos;
}

int posToIndex(const int3 pos, const int3 size, const bool alt){
    return alt ? (pos.y * size.x * size.z + pos.z * size.x + pos.x) : (pos.z * size.x * size.y + pos.y * size.x + pos.x);
}
        

kernel void transposeAll(device const int32_t* image [[buffer(0)]],
                         device int32_t* axial [[buffer(1)]],
                         device int32_t* coronal [[buffer(2)]],
                         device int32_t* sagittal [[buffer(3)]],
                         device const int& x [[buffer(4)]],
                         device const int& y [[buffer(5)]],
                         device const int& z [[buffer(6)]],
                         device const bool& alt [[buffer(7)]],
                         uint index [[thread_position_in_grid]]){
    
    if(int(index) >= x * y * z){
        axial[index] = index;
        return;
    }
    
    int3 size = int3(x,y,z);
    
    int3 axialPos = indexToPos(index, x, y, z);
    int axialI = posToIndex(int3(axialPos.x, axialPos.y, axialPos.z), size, alt);

    int3 coronalPos = indexToPos(index, x, z, y);
    int coronalI = posToIndex(int3(coronalPos.x, coronalPos.z, coronalPos.y), size, alt);

    int3 sagittalPos = indexToPos(index, z, y, x);
    int sagittalI = posToIndex(int3(sagittalPos.z, sagittalPos.y, sagittalPos.x), size, alt);
    
    axial[index] = image[axialI];
    coronal[index] = image[coronalI];
    sagittal[index] = image[sagittalI];
}
