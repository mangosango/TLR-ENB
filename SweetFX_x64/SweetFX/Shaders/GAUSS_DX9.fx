
// Implementation based on the article "Efficient Gaussian blur with linear sampling"
// http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

#include "..\..\SweetFX_preset.txt"

static const float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
static const float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };

texture2D frameTex2D;
texture2D origframeTex2D;

#define CoefLuma            float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
#define sharp_strength_luma (CoefLuma * GaussStrength + 0.2)
#define sharp_clampG        0.035

sampler2D frameSampler
{
    Texture = <frameTex2D>;
    AddressU  = Clamp; AddressV = Clamp;
    MipFilter = None; MinFilter = Linear; MagFilter = Linear;
    SRGBTexture = false;
};

sampler2D origframeSampler
{
    Texture = <origframeTex2D>;
    AddressU  = Clamp; AddressV = Clamp;
    MipFilter = None; MinFilter = Linear; MagFilter = Linear;
    SRGBTexture = false;
};

struct VSOUT
{
	float4 vertPos : POSITION;
	float2 UVCoord : TEXCOORD0;
};

struct VSIN
{
	float4 vertPos : POSITION0;
	float2 UVCoord : TEXCOORD0;
};

VSOUT FrameVS(VSIN IN)
{
	VSOUT OUT;
	OUT.vertPos = IN.vertPos;
	OUT.UVCoord = IN.UVCoord;
	return OUT;
}

float4 BrightPassFilterPS(VSOUT IN) : COLOR0
{
	float4 color = tex2D(frameSampler, IN.UVCoord);
	return float4 (color.rgb * pow (abs (max (color.r, max (color.g, color.b))), 2.0), 1.0f);
}

float4 HGaussianBlurPS(VSOUT IN) : COLOR0
{
	float4 color = tex2D(frameSampler, IN.UVCoord) * sampleWeights[0];
	for(int i = 1; i < 5; ++i) {
		color += tex2D(frameSampler, IN.UVCoord + float2(sampleOffsets[i] * PIXEL_SIZE.x, 0.0)) * sampleWeights[i];
		color += tex2D(frameSampler, IN.UVCoord - float2(sampleOffsets[i] * PIXEL_SIZE.x, 0.0)) * sampleWeights[i];
	}
	return color;
}

float4 VGaussianBlurPS(VSOUT IN) : COLOR0
{
	float4 color = tex2D(frameSampler, IN.UVCoord) * sampleWeights[0];
	for(int i = 1; i < 5; ++i) {
		color += tex2D(frameSampler, IN.UVCoord + float2(0.0, sampleOffsets[i] * PIXEL_SIZE.y)) * sampleWeights[i];
		color += tex2D(frameSampler, IN.UVCoord - float2(0.0, sampleOffsets[i] * PIXEL_SIZE.y)) * sampleWeights[i];
	}
	return color;
}

float4 CombinePS(VSOUT IN) : COLOR0
{
	// Unsharpmask ( Ref. http://www.bigano.com/index.php/en/consulting/40-davide-barranca/90-davide-barranca-notes-on-sharpening.html?start=1 )
	// return tex2D(origframeSampler, IN.UVCoord); // Unprocessed image
	// return tex2D(frameSampler, IN.UVCoord);     // Blurred image

	float4 orig = tex2D(origframeSampler, IN.UVCoord);
	float4 blur = tex2D(frameSampler, IN.UVCoord);
	float3 sharp;

	#if (GaussEffect == 0)
		// Blur...
		orig = lerp(orig, blur, GaussStrength);
	#elif (GaussEffect == 1)
		// Sharpening
		sharp = orig.rgb - blur.rgb;
		float sharp_luma = dot(sharp, sharp_strength_luma);
		sharp_luma = clamp(sharp_luma, -sharp_clampG, sharp_clampG);
		orig = orig + sharp_luma;
	#elif (GaussEffect == 2)
		// Bloom
		#if (GaussBloomWarmth == 0)
			orig = lerp(orig, blur *4, GaussStrength);                                     // Neutral
		#elif (GaussBloomWarmth == 1)
			orig = lerp(orig, max(orig *1.8 + (blur *5) - 1.0, 0.0), GaussStrength);       // Warm and cheap
		#else
			orig = lerp(orig, (1.0 - ((1.0 - orig) * (1.0 - blur *1.0))), GaussStrength);  // Foggy bloom
		#endif
	#elif (GaussEffect == 3)
		// Sketchy
		sharp = orig.rgb - blur.rgb;		
		orig = float4(1.0, 1.0, 1.0, 0.0) - min(orig, dot(sharp, sharp_strength_luma)) *3;
		// orig = float4(1.0, 1.0, 1.0, 0.0) - min(blur, orig);      // Negative
	#endif

	return orig;
}

technique t0
{
	pass P0
	{
		VertexShader = compile vs_3_0 FrameVS();
		PixelShader = compile ps_3_0 BrightPassFilterPS();
        AlphaBlendEnable = false;
		SRGBWriteEnable = false;
	}

	pass P1
	{
		VertexShader = compile vs_3_0 FrameVS();
		PixelShader = compile ps_3_0 HGaussianBlurPS();
        AlphaBlendEnable = false;
		SRGBWriteEnable = false;
	}

	pass P2
	{
		VertexShader = compile vs_3_0 FrameVS();
		PixelShader = compile ps_3_0 VGaussianBlurPS();
		AlphaBlendEnable = false;
		SRGBWriteEnable = false;
	}

	pass P3
	{
		VertexShader = compile vs_3_0 FrameVS();
		PixelShader = compile ps_3_0 CombinePS();
		AlphaBlendEnable = false;
		SRGBWriteEnable = false;
	}
}