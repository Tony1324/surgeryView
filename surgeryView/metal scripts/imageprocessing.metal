//
//  imageprocessing.metal
//  surgeryViewImageProcessingTest
//
//  Created by Tony Zhang on 8/19/24.
//

#include <metal_stdlib>
using namespace metal;

kernel void adjustSizeInt32(device const int32_t* inData [[ buffer(0) ]],
                            device uint8_t* outData [[ buffer(1) ]],
                            device const int& lower [[ buffer(2) ]],
                            device const int& upper [[ buffer(3) ]],
                            uint index [[ thread_position_in_grid ]]) {
    int lowerBound = lower;
    int upperBound = upper;
    
    int32_t value = inData[index];

    // Clamp the value within the specified bounds
    if (value < lowerBound) {
        value = lowerBound;
    } else if (value > upperBound) {
        value = upperBound;
    }

    float normalized = float(value - lowerBound) / float(upperBound - lowerBound);
    uint8_t scaledValue = uint8_t(normalized * 255.0f);

    outData[index] = scaledValue;
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
                         device const int3& size [[buffer(4)]],
                         device const bool& alt [[buffer(5)]],
                         uint index [[thread_position_in_grid]]){
    
    int3 axialPos = indexToPos(index, size.x, size.y, size.z);
    int axialI = posToIndex(axialPos, size, alt);

    // Calculate 3D position for the given 1D index in the coronal plane
    int3 coronalPos = indexToPos(index, size.x, size.z, size.y);
    int coronalI = posToIndex(coronalPos, int3(size.x, size.z, size.y), alt);

    // Calculate 3D position for the given 1D index in the sagittal plane
    int3 sagittalPos = indexToPos(index, size.z, size.y, size.x);
    int sagittalI = posToIndex(sagittalPos, int3(size.z, size.y, size.x), alt);
    
    // Transpose the data from the original image into the different planes
    axial[axialI] = image[index];
    coronal[coronalI] = image[index];
    sagittal[sagittalI] = image[index];
    
}
