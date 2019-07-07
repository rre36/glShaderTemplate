#version 120
//can be anything up to 450, 120 is still common due to compatibility reasons, but i suggest something from 130 upwards so you can use the new "varying" syntax, i myself usually use "400 compatibility"

//uniforms
uniform sampler2D gcolor; 	//colortex0, scene color
uniform sampler2D gdepth;	//colortex1, can be used for anything nowadays since we have depthtex0 and 1
uniform sampler2D shadow; 	//shadowtex0 with optifine

//shadowmap resolution
/* SHADOWRES:4096 */

//shadowdistance
/* SHADOWHPL:100.0 */

//input from vertex
varying vec4 texcoord; 	//a vec2 with the xy-components would already be enough here

//uniforms (projection matrices)
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;


/* functions to be called in main and global variables go here */

void main() { 	//code goes here
	//get screen-/viewspace position
	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0 - 1.0, texcoord.t * 2.0 - 1.0, 2.0 * texture2D(gdepth, texcoord.st).x - 1.0, 1.0);
	fragposition /= fragposition.w;

	float distance = sqrt(fragposition.x * fragposition.x + fragposition.y * fragposition.y + fragposition.z * fragposition.z); 	//used for shadow fading

	float shading = 1.0;

	if (distance < 25.0 && distance > 0.1) {

		vec4 worldposition = gbufferModelViewInverse * fragposition; 	//screen-/viewspace to worldspace

		float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
		float yDistanceSquared  = worldposition.y * worldposition.y;
		
		if (yDistanceSquared < 225.0) {

			//transform world position to shadowspace, old "slow" method but best to understand it
			worldposition = shadowModelView * worldposition;
			float comparedepth = -worldposition.z;
			worldposition = shadowProjection * worldposition;
			worldposition /= worldposition.w;			
			worldposition.st = worldposition.st * 0.5 + 0.5;

			//get shadows if condition is true to avoid unnecessary shadowmap samples
			if (comparedepth > 0.0 && worldposition.s < 1.0 && worldposition.s > 0.0 && worldposition.t < 1.0 && worldposition.t > 0.0){
				float shadowMult = min(1.0 - xzDistanceSquared / 625.0, 1.0) * min(1.0 - yDistanceSquared / 225.0, 1.0);	//shadow fade, there are better ways to do this
				float shadowSample = texture2D(shadow, worldposition.st).z; 			//sample shadowmap depth
				float shadowDepth = 0.05 + shadowSample * (256.0 - 0.05); 				//do maths on it so that it can be compared to comparedepth
				shading = 1.0 - shadowMult * (clamp(comparedepth - shadowDepth - 0.1, 0.0, 0.5) * 0.6 - 0.1); 	//get shadow
			}
		}
	}

	//write to framebuffer attachment
	gl_FragData[0] = texture2D(gcolor, texcoord.st);
	gl_FragData[1] = texture2D(gdepth, texcoord.st);
	gl_FragData[3] = vec4(texture2D(gcolor, texcoord.st).rgb * shading, 1.0);
}
