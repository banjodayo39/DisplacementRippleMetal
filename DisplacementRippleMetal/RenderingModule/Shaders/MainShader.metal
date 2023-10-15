//
//  Shaders.metal
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 3/28/23.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
    float2 textureCoordinates [[ attribute(2) ]];
    
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 textureCoordinates;
};

vertex VertexOut vertex_main(const VertexIn vertices [[ stage_in]]) {
    VertexOut vOut;
    
    vOut.position = vertices.position;
    vOut.color = vertices.color;
    vOut.textureCoordinates = vertices.textureCoordinates;
    
    return vOut;
}

fragment float4 fragment_main(VertexOut vertexIn [[ stage_in ]],
                              constant Uniforms &uniforms [[buffer(0)]],
                              sampler sample2d [[ sampler(0) ]],
                              texture2d<float> texture [[texture(0)]]) {
    
    float2 uv = vertexIn.position.xy / uniforms.resolution;
    float3 col3 = 0.5 + 0.5 * cos(sin(uniforms.time) + uv.xyx + float3(0, 2, 4));
    
    return float4(col3, 1.0);
}
