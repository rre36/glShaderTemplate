#version 120
//can be anything up to 450, 120 is still common due to compatibility reasons, but i suggest something from 130 upwards so you can use the new "varying" syntax, i myself usually use "400 compatibility"

//include math functions from file
#include "/lib/math.glsl"

//uniforms
uniform sampler2D colortex0; 	//scene color
uniform sampler2D depthtex0;	//scene depth
uniform sampler2D shadowtex0; 	//shadowdepth

//shadowmap resolution
const int shadowMapResolution   = 4096;

//shadowdistance
const float shadowDistance      = 128.0;

//input from vertex
varying vec2 texcoord; 	//scene texture coordinates
varying vec3 lightVec;

varying vec3 sunlightColor;
varying vec3 skylightColor;

uniform vec3 cameraPosition;

//uniforms (projection matrices)
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelView;

//include position transform files
#include "/lib/transforms.glsl"
#include "/lib/shadowmap.glsl"

/* functions to be called in main and global variables go here */
vec3 sceneColor 	= vec3(0.0);
float sceneDepth	= 0.0;

//function to calculate position in shadowspace
vec3 getShadowCoordinate(in vec3 screenpos, in float bias, out float comparedepth) {
	vec3 position 	= screenpos;
		position   += vec3(bias)*lightVec;
		position 	= viewMAD(gbufferModelViewInverse, position);
		position 	= viewMAD(shadowModelView, position);
		position 	= projMAD(shadowProjection, position);
		position.z *= 0.2;

	float distortion = 1.0;
		warpShadowmap(position.xy, distortion);

	vec3 temppos 	= position;
		temppos.xy *= distortion;
		temppos 	= projMAD(shadowProjectionInverse, temppos);
		comparedepth = -temppos.z;

	return position*0.5+0.5;
}

//calculate shadow
float getShadow(sampler2D shadowtex, in vec3 shadowpos, in float comparedepth) {
	const float diff = 0.06; 	//a fade value for the shadows
	float depth 	= texture2D(shadowtex, shadowpos.xy).x*256.0;
	float shadow 	= comparedepth-depth;
		shadow 	    = clamp(shadow, 0.0, diff)/diff;

	return 1.0-shadow;
}

void main() {
	//sample necessary scene textures
	sceneColor 	= texture2D(colortex0, texcoord).rgb;
	sceneColor 	= pow(sceneColor, vec3(2.2)); 	//linearize scene color
	sceneDepth 	= texture2D(depthtex0, texcoord).x;

	//calculate necessary positions
	vec3 screenpos 	= getScreenpos(sceneDepth, texcoord);

	//make terrain mask
	bool isTerrain 	= sceneDepth < 1.0;

	//variables for shadow calculation
	float shadow 		= 1.0;
	float comparedepth 	= 0.0;

	if (isTerrain) {
		vec3 shadowcoord 	= getShadowCoordinate(screenpos, 0.06, comparedepth);
			shadow 			= getShadow(shadowtex0, shadowcoord, comparedepth);

		vec3 lightcolor 	= sunlightColor*shadow + skylightColor;

		sceneColor 		   *= lightcolor;
	}


	//write to framebuffer attachment
	/*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(sceneColor, 1.0);
}
