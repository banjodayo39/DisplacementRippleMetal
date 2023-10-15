//
//  ShaderTypes.h
//  DisplacementRippleMetal
//
//  Created by Dayo Banjo on 10/14/23.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#import <simd/simd.h>


typedef struct Uniforms {
    simd_float2 resolution;
    simd_float2 mouse;
    float time;
} Uniforms;

#endif /* ShaderTypes_h */
