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
