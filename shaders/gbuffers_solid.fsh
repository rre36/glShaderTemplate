uniform sampler2D tex;
uniform sampler2D lightmap;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

void main() {
	/*DRAWBUFFERS:01*/
	gl_FragData[0] = texture2D(tex, texcoord.st) * texture2D(lightmap, lmcoord.st) * color;
	gl_FragData[1] = vec4(normal*0.5+0.5, 1.0);
}