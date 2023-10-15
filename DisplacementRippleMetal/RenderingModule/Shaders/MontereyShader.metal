//
//  MontereyShader.metal
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 3/30/23.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderTypes.h"

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 textureCoordinates;
};

float sin_shape(float2 uv, float offset_y, float time) {
    // Time varying pixel color
    float y = sin((uv.x + time * -0.06 + offset_y) * 5.5);
    float x = uv.x * 8.;
    float a=1.;
    for (int i=0; i<5; i++) {
        x*=0.53562;
        x+=6.56248;
        y+=sin(x)*a;
        a*=.5;
    }
    float y0 = step(0.0, y * 0.08 - uv.y + offset_y);
    return y0;
}

float2 rotate(float2 coord, float alpha) {
    float cosA = cos(alpha);
    float sinA = sin(alpha);
    return float2(coord.x * cosA - coord.y * sinA, coord.x * sinA + coord.y * cosA);
}

float3 spectrumWaves(float2 uv, float time) {
    float3 col = float3(0.0, 0.0, 0.0);
    col += sin_shape(uv, 0.3, time) * 0.2;
    col += sin_shape(uv, 0.7, time) * 0.2;
    col += sin_shape(uv, 1.1, time) * 0.2;
    float3 fragColor;
    if (col.x >= 0.8 ) {
        fragColor = float3(0.96, 0.77, 0.77); // light pink
    } else if (col.x >= 0.6) {
        fragColor = float3(0.96, 0.52, 0.71); // light magenta
    } else if (col.x >= 0.4) {
        fragColor = float3(0.96, 0.33, 0.56); // deep pink
    } else if (col.x >= 0.2) {
        fragColor = float3(0.96, 0.21, 0.38); // magenta red
    } else if (col.x >= 0.1) {
        fragColor = float3(0.95, 0.10, 0.25); // scarlet red
    } else {
        fragColor = float3(0.94, 0.00, 0.14); // vermillion red
    }
    
    return fragColor;
}

fragment half4 fragment_monterey(VertexOut vertexIn [[ stage_in ]],
                                 constant Uniforms &uniforms [[buffer(0)]],
                                 sampler sample2d [[ sampler(0) ]],
                                 texture2d<float> texture [[texture(0)]])
{
    float2 fragCoord = vertexIn.position.xy;
    float2 resolution = uniforms.resolution;
    float time = uniforms.time;
    fragCoord = rotate(fragCoord + float2(0.0, -300.0), 0.5);
    
    // Normalized pixel coordinates (from 0 to 1)
    float3 col0 = spectrumWaves((fragCoord * 2.0) / resolution.xy, time);
    float3 col1 = spectrumWaves(((fragCoord * 2.0) + float2(1.0, 0.0)) / resolution.xy, time);
    float3 col2 = spectrumWaves(((fragCoord * 2.0) + float2(1.0, 1.0)) / resolution.xy, time);
    float3 col3 = spectrumWaves(((fragCoord * 2.0) + float2(0.0, 1.0)) / resolution.xy, time);
    
    float4 fragColor = float4((col0 + col1 + col2 + col3) / 4.0, 1.0);
    
    float2 uv = fragCoord / resolution.xy;
    float4 tex_color = texture.sample(sample2d, uv);
    fragColor.xyz *= (uv.y * 1.08 + 0.65) * tex_color.xyz;
    
    return half4(half3(col3), 1.0);
}



