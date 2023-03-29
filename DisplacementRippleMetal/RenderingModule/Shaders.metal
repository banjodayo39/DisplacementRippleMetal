//
//  Shaders.metal
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 3/28/23.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
    float2 textureCoordinates [[ attribute(2) ]];
    
};

struct Constants {
    float animatedBy;
    float2 resolution;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 textureCoordinates;
    float time;
    float2 resolution;
};



vertex VertexOut vertex_main(const VertexIn vertices [[ stage_in]],
                               constant Constants &constants [[ buffer(1) ]])
{
    VertexOut v;
    v.position = vertices.position;
    v.color = vertices.color;
    v.textureCoordinates = vertices.textureCoordinates;
    v.time = constants.animatedBy;
    v.resolution = constants.resolution;
    return v;
}

constant float PI = 3.14159265359;

float concentric(float2 m, float repeat, float t) {
    float r = length(m);
    float v = sin((1.0 - r) * (1.0 - r) * repeat + t) * 0.5 + 0.5;
    return v;
}

float radial(float2 m, float2 repeat, float t) {
    float r = length(m);
    float a = abs(atan2(m.y, m.x) + PI);
    float v = sin(a * repeat.x + sin(r * repeat.y) + t) * 0.5 + 0.5;
    return v;
}

float spiral(float2 m, float repeat, float dir, float t) {
    float r = length(m);
    float a = atan2(m.y, m.x);
    float v = sin(repeat * (sqrt(r) + (1.0 / repeat) * dir * a - t)) * 0.5 + 0.5;
    return v;
}

fragment float4 fragment_main(VertexOut vertexIn [[ stage_in ]],
                               sampler sample2d [[ sampler(0) ]],
                               texture2d<float> texture [[texture(0)]]) {
    //### Simple Diaplacxement Ripple with Metal swift 
    float aspect = vertexIn.resolution.x / vertexIn.resolution.y;
    float2 uv = (float2(vertexIn.position.xy) / vertexIn.resolution.xy * 2.0 - 1.0) * float2(1.0, 1.0 / aspect);
    float r = length(uv);
    float iTime = vertexIn.time ;
    float c0 = 1.0 - sin(r * r) * 2.0;
    float c1 = concentric(uv, 50.0, iTime * 3.0) * 0.5 + 0.5;
    float c2 = radial(uv, float2(5.0, 30.0), iTime * 4.0) * 0.2 + 0.8;
    float c3 = spiral(uv, 90.0, 1.0, iTime * 0.1) * 0.9 + 0.1;
    float c4 = spiral(uv, 60.0, -1.0, iTime * 0.1) * 0.8 + 0.2;
    
    float3 col = float3(c0 * c1 * c2 * c3 * c4);
    return float4(col, 1);
    
    float EPSILON = 0.05;
    float FOV = 90.0;
    
    float FOV_SCALE = 20.0 / FOV;
    // float iTime = vertexIn.time;
    float2 iResolution = vertexIn.resolution;
    //  float2 uv = vertexIn.position.xy / iResolution.xy - float2(0.5, 0.5);
    uv.y *= iResolution.y / iResolution.x;
    
    float3 rp = float3(0.0, 0.0, fmod(iTime, 100.0));
    float3 rd = normalize(float3(sin(iTime * 0.5), 0.0, cos(iTime)));
    float3 rr = cross(rd, float3(0.0, 1.0, 0.0));
    rd = normalize(rd * FOV_SCALE + uv.x * rr + uv.y * cross(rd, rr));
    rr = float3(cos(iTime), sin(iTime * 0.2), 0.0);
    
    float3 c = float3(0.0);
    float d = 0.0, dp;
    for (int i = 0; i < 256; i++) {
        float3 lr = fmod(rp, 1.0) - float3(0.5, 0.5, 0.5);
        dp = max(0.1, min(1.0, (abs(lr.z) + abs(lr.x)) * abs(cos(rp.y) * 0.7) * 1.05));
        d = length(lr) - dp;
        c += max(0.0, 1.0 - d) * 0.003; // * iChannel0.sample(iChannel0Sampler, (rp.xy + rp.yz) * 0.1).xyz;
        
        if (d < EPSILON)
            break;
        
        rp += d * rd * 0.2;
        rd = normalize(rr * d * 0.1 + rd);
    }
    
    constexpr sampler defaultSampler;
    if (d < EPSILON) {
        c += texture.sample(sample2d, (rp.xy + rp.yz) * 0.1).xyz * 0.2;
    }
    
    return float4(c.xyz, 1.0);
    
}
