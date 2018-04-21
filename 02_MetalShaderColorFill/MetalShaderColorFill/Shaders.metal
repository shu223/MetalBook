//
//  Shaders.metal
//  MetalShaderColorFill
//
//  Created by Shuichi Tsutsumi on 2017/09/23.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ColorInOut
{
    float4 position [[ position ]];
};

vertex ColorInOut vertexShader(device float4 *positions [[ buffer(0) ]],
                               uint           vid       [[ vertex_id ]])
{
    ColorInOut out;
    out.position = positions[vid];
    return out;
}

fragment float4 fragmentShader(ColorInOut in [[ stage_in ]])
{
    return float4(1,0,0,1);
}

