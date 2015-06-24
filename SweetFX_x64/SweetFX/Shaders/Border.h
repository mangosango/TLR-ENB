  /*-----------------------------------------------------------.
 /                          Border                            /
'-----------------------------------------------------------*/
// Version 1.2

/*
Version 1.0 by Oomek
- Fixes light, one pixel thick border in some games when forcing MSAA like i.e. Dishonored

Version 1.1 by CeeJay.dk
- Optimized the shader. It still does the same but now it runs faster.

Version 1.2 by CeeJay.dk
- Added border_width and border_color features
*/


float4 BorderPass( float4 colorInput, float2 tex )
{
float3 border_color_float = border_color / 255.0;
float2 distance = abs(tex - 0.5); //calculate distance from center

//bool2 screen_border = step(distance,0.5 - (pixel * border_width)); //is the distance less than the max - border_width?
bool2 screen_border = step(0.5 - (pixel * border_width),distance); //is the distance greater than the max - border_width?


colorInput.rgb = (!dot(screen_border, 1.0)) ? colorInput.rgb : border_color_float; //if neither x or y is greater then do nothing, but if one them is greater then set the color to border_color.
//colorInput.rgb = saturate(colorInput.rgb - dot(screen_border, 1.0));
//colorInput.rgb = colorInput.rgb * screen_border.x - !screen_border.y;

return colorInput; //return the pixel

}