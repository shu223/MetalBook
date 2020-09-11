//
//  Shaders.metal
//  ARMetalArgumentBuffers
//
//  Created by Shuichi Tsutsumi on 2017/09/01.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct ColorInOut
{
    float4 position [[ position ]];
    float2 texcoord;
};

struct ShaderInputs {
    texture2d<float> snapshotTexture;
    texture2d<float> cameraTexture;
    sampler textureSampler;
    float time;
};

vertex ColorInOut vertexShader(const device float4* positions [[ buffer(0) ]],
                               const device float2* texcoords [[ buffer(1) ]],
                               const        uint    vid       [[ vertex_id ]])
{
    ColorInOut out;
    out.position = positions[vid];
    out.texcoord = texcoords[vid];
    return out;
}

// based on: https://www.shadertoy.com/view/MsX3DN
fragment float4 fragmentShader(ColorInOut            in      [[ stage_in ]],
                               constant ShaderInputs &inputs [[ buffer(0) ]])
{
    float4 color = inputs.snapshotTexture.sample(inputs.textureSampler, in.texcoord);
    
    if (color.r == 0.0 && color.g == 0.0 && color.b == 0.0)
    {
        float2 uv = in.texcoord;
        float duration = 2;
        float x_offset = sin(uv.y * 20.0 + inputs.time) / duration;
        x_offset *= 0.1;
        uv.x += x_offset;

        color = inputs.cameraTexture.sample(inputs.textureSampler, uv);
        float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
        color = float4(gray);
    }
    
    return color;
}
