#version 120

varying vec3 lightVec;

varying vec2 texcoord;

varying vec3 sunlightColor;
varying vec3 skylightColor;

uniform vec3 shadowLightPosition;

void main() {
	gl_Position = ftransform();

	sunlightColor = vec3(1.0, 1.0, 1.0);
	skylightColor = vec3(0.1, 0.1, 0.1);
	
	texcoord 	= gl_MultiTexCoord0.xy;
	lightVec	= normalize(shadowLightPosition);
}
