//
//  File.metal
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 10/15/23.
//

#include <metal_stdlib>
using namespace metal;
#include "ShaderUtils.metal"

float circleshape(float2 position, float radius, float blur) {
    return smoothstep(radius, radius-blur, length(position));
}



