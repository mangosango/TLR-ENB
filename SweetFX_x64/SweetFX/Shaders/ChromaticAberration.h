/*------------------------------------------------------------------------------
			Chromatic Aberration
------------------------------------------------------------------------------*/

#define CHROMA_POW		35.0
 
float3 fvChroma = float3(0.995, 1.000, 1.005);
 
float4 ChromaticAberrationFocus(float2 tex, float outOfFocus)
{
	float3 chroma = pow(fvChroma, CHROMA_POW * outOfFocus);

	float2 tr = ((2.0 * tex - 1.0) * chroma.r) * 0.5 + 0.5;
	float2 tg = ((2.0 * tex - 1.0) * chroma.g) * 0.5 + 0.5;
	float2 tb = ((2.0 * tex - 1.0) * chroma.b) * 0.5 + 0.5;
	
	float3 color = float3(myTex2D(s0, tr).r, myTex2D(s0, tg).g, myTex2D(s0, tb).b) * (1.0 - outOfFocus);
	
	return float4(color, 1.0);
}

float4 CAPass(float4 colorInput, float2 tex)
{
	return ChromaticAberrationFocus(tex, outfocus);
}