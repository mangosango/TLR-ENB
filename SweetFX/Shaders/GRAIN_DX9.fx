/**
 * Copyright (C) 2012 Jorge Jimenez (jorge@iryoku.com). All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
 * IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are 
 * those of the authors and should not be interpreted as representing official
 * policies, either expressed or implied, of the copyright holders.
 */

#include "..\..\SweetFX_preset.txt"

cbuffer UpdatedOncePerFrame {
    float2 pixelSize;
    float noiseIntensity;
    float exposure;
    float t;
}

Texture2D srcTex;
Texture3D noiseTex;

sampler2D LinearSampler {
    Texture = <srcTex>;
    AddressU = Clamp;
	AddressV = Clamp;
    MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
    SRGBTexture = false;
};

sampler2D LinearSamplerWrap {
    Texture = <noiseTex>;	
    AddressU = Wrap;
	AddressV = Wrap;
	AddressW = Wrap;
    MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
    SRGBTexture = false;
};


void PassVS(float4 position : POSITION,
            out float4 svposition : SV_POSITION,
            inout float2 texcoord : TEXCOORD0) {
    svposition = position;
}


float3 Overlay(float3 a, float3 b) {
    return pow(abs(b), 2.2) < 0.5? 2 * a * b : 1.0 - 2 * (1.0 - a) * (1.0 - b);
}


float3 AddNoise(float3 color, float2 texcoord) {
    float2 coord = texcoord * FilmGrainSize;
    coord.x *= pixelSize.y / pixelSize.x;
    //float noise = noiseTex.Sample(LinearSamplerWrap, float3(coord, t)).r;
    float noise = tex2D(LinearSamplerWrap, coord + float2(t, t *4)).r;
    float exposureFactor = exposure / 2.0;
    exposureFactor = sqrt(exposureFactor);
    float t = lerp(3.5 * noiseIntensity, 1.13 * noiseIntensity, exposureFactor);
    return Overlay(color, lerp(0.5, noise, t));
}


float4 FilmGrainPS(float4 position : SV_POSITION,
                   float2 texcoord : TEXCOORD0) : COLOR {
	float3 color = tex2D(LinearSampler, texcoord).rgb;
    color = AddNoise(color, texcoord);
    return float4(color, 1.0);
}


technique FilmGrain {
    pass FilmGrain {	
        VertexShader = compile vs_3_0 PassVS();
        PixelShader = compile ps_3_0 FilmGrainPS();
        
        SRGBWriteEnable = false;
        AlphaBlendEnable = false;		
        StencilEnable = false;
    }
}