//++++++++++++++++++++++++++++++++++++++++++++
// ENBSeries effect file
// visit http://enbdev.com for updates
// Copyright 2007-2011 (c) Boris Vorontsov
//++++++++++++++++++++++++++++++++++++++++++++

//temporary variables
float4	tempF1;
float4	tempF2;


//global variable externally set, do not change
float4	ELenzParameters;//Lenz reflection intensity, lenz reflection power
float4	BloomParameters; //BloomRadius1, BloomRadius2, BloomBlueShiftAmount, BloomContrast
float4	TempParameters;
float4	ScreenSize;
//x=generic timer in range 0..1, period of 16777216 ms (4.6 hours)
//w=frame time elapsed (in seconds)

//quad
struct VS_OUTPUT_POST
{
	float4 vpos  : POSITION;
	float2 txcoord0 : TEXCOORD0;
};
struct VS_INPUT_POST
{
	float3 pos  : POSITION;
	float2 txcoord0 : TEXCOORD0;
};

texture2D texBloom1;
texture2D texBloom2;
texture2D texBloom3;
texture2D texBloom4;
texture2D texBloom5;
texture2D texBloom6;

sampler2D SamplerBloom1 = sampler_state
{
    Texture   = <texBloom1>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;//NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerBloom2 = sampler_state
{
    Texture   = <texBloom2>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;//NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerBloom3 = sampler_state
{
    Texture   = <texBloom3>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;//NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerBloom4 = sampler_state
{
    Texture   = <texBloom4>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;//NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerBloom5 = sampler_state
{
    Texture   = <texBloom5>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;//NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerBloom6 = sampler_state
{
    Texture   = <texBloom6>;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;//NONE;
	AddressU  = Clamp;
	AddressV  = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};


//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
VS_OUTPUT_POST VS_Bloom(VS_INPUT_POST IN)
{
	VS_OUTPUT_POST OUT;

	OUT.vpos=float4(IN.pos.x,IN.pos.y,IN.pos.z,0);

	OUT.txcoord0.xy=IN.txcoord0.xy+TempParameters.xy;//0/(bloomtexsize*2.0)

	return OUT;
}


//zero pass HQ, input texture is fullscreen
//SamplerBloom1 - fullscreen texture
float4 PS_BloomPrePass(VS_OUTPUT_POST In) : COLOR
{
	float4 bloomuv;

	float4 bloom=tex2D(SamplerBloom1, In.txcoord0);
	const float2 offset[4]=
	{
		float2(0, 0),
		float2(0.0, 0),
		float2(0, 0),
		float2(0, 0)
	};
	float2 screenfact=0;
	screenfact.y*=ScreenSize.z;
	//TempParameters.w==1 if first pass, ==2 is second pass
	screenfact.xy*=TempParameters.z*0.25;
	float4 srcbloom=bloom;
	for (int i=0; i<4; i++)
	{
		bloomuv.xy=offset[i];
		bloomuv.xy=(bloomuv.xy*screenfact.xy)+In.txcoord0.xy;//-(1.0/256.0);//-(1.0/512.0);
	//	bloom+=tex2D(SamplerBloom1, bloomuv.xy);
		float4 tempbloom=tex2D(SamplerBloom1, bloomuv.xy);
//		bloom.xyz=max(bloom.xyz, tempbloom.xyz*0.99);
		bloom.xyz+=tempbloom.xyz;
	}
	bloom*=0.2;

/*
	//for first pass modify bloom curve by making it more contrast
	if (TempParameters.w<1.1)
	{
		bloom.xyz*=0.8;
		float3 color=bloom.xyz;//tempF1.y;//0
		color.xyz+=0.000002;
		float3	ncol=normalize(color.xyz);
		float3	scl=color.xyz/ncol.xyz;
		scl=pow(scl, 1.5);//_c192.z
	//	ncol.xyz=pow(ncol.xyz, 1.0*tempF2.x);//_c192.w
		color.xyz=scl*ncol.xyz;
		//color.xyz=color.xyz/(0.9 + color.xyz);
	//	color.xyz*=1.0*tempF1.w;//1.8;//_c191.w;
		bloom.xyz=color.xyz;
	}*/



	bloom.w=1.0;
	return bloom;
}



//first and second passes draw to every texture
//twice, after computations of these two passes,
//result is set as input to next cycle

//first pass
//SamplerBloom1 is result of prepass or second pass from cycle
float4 PS_BloomTexture1(VS_OUTPUT_POST In) : COLOR
{
	float4 bloomuv;

	float4 bloom=tex2D(SamplerBloom1, In.txcoord0);
	const float2 offset[8]=
	{
		float2(0.707, 0.707),
		float2(0.707, -0.707),
		float2(-0.707, 0.707),
		float2(-0.707, -0.707),
		float2(0.0, 1.0),
		float2(0.0, -1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};
	float2 screenfact=1.0;
	screenfact.y*=ScreenSize.z;
	screenfact.xy/=ScreenSize.x;
	float4 srcbloom=bloom;
	//TempParameters.w == (1+passnumber)
	float step=(TempParameters.w-0.25);
//	float step=(TempParameters.w);//
	screenfact.xy*=step;//====================================================

	float4 bloomadd=bloom;

	for (int i=0; i<8; i++)
	{
		bloomuv.xy=offset[i]*BloomParameters.x;
		bloomuv.xy=(bloomuv.xy*screenfact.xy)+In.txcoord0.xy;//-(1.0/256.0);//-(1.0/512.0);
		//v1
//		bloomadd+=tex2D(SamplerBloom1, bloomuv.xy);
		//v2
		float4 tempbloom=tex2D(SamplerBloom1, bloomuv.xy);
//		bloomadd+=tempbloom;
//		float fgr=dot(bloom.xyz, 0.333);
//		bloom.xyz=max(bloom.xyz, tempbloom.xyz*0.99);
		bloom+=tempbloom;
	}
	//v1
//	bloomadd*=0.111111;
	bloom*=0.111111;
	//v0
//	bloom.xyz=lerp(bloomadd.xyz, bloom.xyz, 0.5);//BloomParameters.w

	bloom.xyz=max(bloom.xyz, srcbloom);



	//float3 violet=float3(0.78, 0.5, 1.0);
	//float3 violet=float3(0.6, 0.4, 1.0);//v2
	float3 violet=float3(0.6, 0.4, 1.0);//v3

	//this applies when white
	//float gray=0.104*dot(srcbloom.xyz, 0.333);//max(srcbloom.x, max(srcbloom.y, srcbloom.z));
	//this applies on dark and when contrast
	float ttt=dot(bloom.xyz, 0.333)-dot(srcbloom.xyz, 0.333);
	ttt=max(ttt, 0.0);
	float gray=BloomParameters.z*ttt;//max(srcbloom.x, max(srcbloom.y, srcbloom.z));
	float mixfact=(gray/(1.0+gray));
	mixfact*=1.0-saturate((TempParameters.w-1.0)*0.3);
	violet.xy+=saturate((TempParameters.w-1.0)*0.3);
	violet.xy=saturate(violet.xy);
	bloom.xyz*=lerp(1.0, violet.xyz, mixfact);

	bloom.w=1.0;
	return bloom;
}


//second pass
//SamplerBloom1 is result of first pass
float4 PS_BloomTexture2(VS_OUTPUT_POST In) : COLOR
{
	float4 bloomuv;

	float4 bloom=tex2D(SamplerBloom1, In.txcoord0);
	const float2 offset[8]=
	{
		float2(0.707, 0.707),
		float2(0.707, -0.707),
		float2(-0.707, 0.707),
		float2(-0.707, -0.707),
		float2(0.0, 1.0),
		float2(0.0, -1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};
	float2 screenfact=1.0;
	screenfact.y*=ScreenSize.z;
	screenfact.xy/=ScreenSize.x;
	float4 srcbloom=bloom;

	//TempParameters.w == (1+passnumber)
	float step=(TempParameters.w-0.25);
	screenfact.xy*=step;//====================================================
	float4 rotvec=0.0;
	sincos(0.19635, rotvec.x, rotvec.y);
	for (int i=0; i<8; i++)
	{
		bloomuv.xy=offset[i];
		bloomuv.xy=reflect(bloomuv.xy, rotvec.xy);
		bloomuv.xy*=BloomParameters.y;
		//separate code is much faster without constant table operations
		bloomuv.xy=(bloomuv.xy*screenfact.xy)+In.txcoord0.xy;//-(1.0/256.0);//-(1.0/512.0);
		float4 tempbloom=tex2D(SamplerBloom1, bloomuv.xy);
		bloom+=tempbloom;
//		bloom.xyz=max(bloom.xyz, tempbloom.xyz*0.99);
	}
	bloom*=0.111111;//0.125;


//bloom.xyz=max(bloom.xyz, tex2D(SamplerBloom1, In.txcoord0));

	bloom.w=1.0;
	return bloom;
}



//last pass, mix several bloom textures
//SamplerBloom5 is the result of prepass
//float4 PS_BloomPostPass(float2 vPos : VPOS ) : COLOR
float4 PS_BloomPostPass(VS_OUTPUT_POST In) : COLOR
{
	float4 bloom;
/*
	//v1
	bloom =tex2D(SamplerBloom1, In.txcoord0);
	bloom+=tex2D(SamplerBloom2, In.txcoord0);
	bloom+=tex2D(SamplerBloom3, In.txcoord0);
	bloom+=tex2D(SamplerBloom4, In.txcoord0);
//	bloom+=tex2D(SamplerBloom5, In.txcoord0);
	bloom*=0.25;
*/

	//v2
	float4 bloom1=tex2D(SamplerBloom1, In.txcoord0);
	float4 bloom2=tex2D(SamplerBloom2, In.txcoord0);
	float4 bloom3=tex2D(SamplerBloom3, In.txcoord0);
	float4 bloom4=tex2D(SamplerBloom4, In.txcoord0);
//	float4 bloom5=tex2D(SamplerBloom5, In.txcoord0);
	bloom=max(bloom1, bloom2);
	bloom=max(bloom, bloom3);
	bloom=max(bloom, bloom4);
//	bloom=max(bloom, bloom5);
	bloom.w=1.0;



	float3 lenz=0;
	float2 lenzuv=0.0;
	//deepness, curvature, inverse size
	const float3 offset[4]=
	{
		float3(1.6, 4.0, 1.0),
		float3(0.7, 0.25, 2.0),
		float3(0.3, 1.5, 0.5),
		float3(-0.5, 1.0, 1.0)
	};
	//color filter per reflection
	const float3 factors[4]=
	{
		float3(0.3, 0.4, 0.4),
		float3(0.2, 0.4, 0.5),
		float3(0.5, 0.3, 0.7),
		float3(0.1, 0.2, 0.7)
	};

//lenzuv.xy=0.5-lenzuv.xy;
//distfact=0.5-lenzuv.xy-0.5;

	if (ELenzParameters.x>0.00001)
	{
		for (int i=0; i<4; i++)
		{
			float2 distfact=(In.txcoord0.xy-0.5);
			lenzuv.xy=offset[i].x*distfact;
			lenzuv.xy*=pow(2.0*length(float2(distfact.x*ScreenSize.z,distfact.y)), offset[i].y);
			lenzuv.xy*=offset[i].z;
			lenzuv.xy=0.5-lenzuv.xy;//v1
	//		lenzuv.xy=In.txcoord0.xy-lenzuv.xy;//v2
			float3 templenz=tex2D(SamplerBloom2, lenzuv.xy);
			templenz=templenz*factors[i];
			distfact=(lenzuv.xy-0.5);
			distfact*=2.0;
			templenz*=saturate(1.0-dot(distfact,distfact));//limit by uv 0..1
	//		templenz=factors[i] * (1.0-dot(distfact,distfact));
			float maxlenz=max(templenz.x, max(templenz.y, templenz.z));
/*			float3 tempnor=(templenz.xyz/maxlenz);
			tempnor=pow(tempnor, tempF1.z);
			templenz.xyz=tempnor.xyz*maxlenz;
*/
			float tempnor=(maxlenz/(1.0+maxlenz));
			tempnor=pow(tempnor, ELenzParameters.y);
			templenz.xyz*=tempnor;

	//		templenz*=maxlenz*maxlenz;
			lenz+=templenz;
	//		lenz.xyz=max(lenz.xyz, templenz.xyz*0.99);
		}
		lenz.xyz*=0.25;

		bloom.xyz+=lenz.xyz*ELenzParameters.x;
	}

	return bloom;
}



technique BloomPrePass
{
    pass p0
    {
	VertexShader = compile vs_3_0 VS_Bloom();
	PixelShader  = compile ps_3_0 PS_BloomPrePass();

	COLORWRITEENABLE=ALPHA|RED|GREEN|BLUE;
	CullMode=NONE;
	AlphaBlendEnable=FALSE;
	AlphaTestEnable=FALSE;
	SEPARATEALPHABLENDENABLE=FALSE;
	FogEnable=FALSE;
	SRGBWRITEENABLE=FALSE;
	}
}

technique BloomTexture1
{
    pass p0
    {
	VertexShader = compile vs_3_0 VS_Bloom();
	PixelShader  = compile ps_3_0 PS_BloomTexture1();

	COLORWRITEENABLE=ALPHA|RED|GREEN|BLUE;
	CullMode=NONE;
	AlphaBlendEnable=FALSE;
	AlphaTestEnable=FALSE;
	SEPARATEALPHABLENDENABLE=FALSE;
	FogEnable=FALSE;
	SRGBWRITEENABLE=FALSE;
	}
}


technique BloomTexture2
{
    pass p0
    {
	VertexShader = compile vs_3_0 VS_Bloom();
	PixelShader  = compile ps_3_0 PS_BloomTexture2();

	COLORWRITEENABLE=ALPHA|RED|GREEN|BLUE;
	CullMode=NONE;
	AlphaBlendEnable=FALSE;
	AlphaTestEnable=FALSE;
	SEPARATEALPHABLENDENABLE=FALSE;
	FogEnable=FALSE;
	SRGBWRITEENABLE=FALSE;
	}
}

technique BloomPostPass
{
    pass p0
    {
	VertexShader = compile vs_3_0 VS_Bloom();
	PixelShader  = compile ps_3_0 PS_BloomPostPass();

	COLORWRITEENABLE=ALPHA|RED|GREEN|BLUE;
	CullMode=NONE;
	AlphaBlendEnable=FALSE;
	AlphaTestEnable=FALSE;
	SEPARATEALPHABLENDENABLE=FALSE;
	FogEnable=FALSE;
	SRGBWRITEENABLE=FALSE;
	}
}



