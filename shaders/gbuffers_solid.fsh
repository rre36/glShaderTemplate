//we use this for all solid objects because they get rendered the same way anyways
//redundant code can be handled like this as an include to make your life easier

uniform sampler2D tex; 		//this is our albedo texture. optifine's "default" name for this is "texture" but that collides with the texture() function of newer OpenGL versions. We use "tex" or "gcolor" instead, although it is just falling back onto the same sampler as an undefined behavior
uniform sampler2D lightmap;	//the vanilla lightmap texture, basically useless with shaders

//these are our inputs from the vertex shader
varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

void main() {
	/*
	These are our framebuffer attachments. The drawbuffers command tells optifine that we want to write to
	colortex0, 1 and 2. This is necessary to make all the data we might need later in deferred or composite
	available there by just reading a buffer texture (eg. normals for diffuse shading or lightmaps).
	The buffers can also be set to different formats to allow for more precision etc.
	See deferred.fsh for that.

	It's important that you have some kind of structure going on because this is the heart of your
	shaders pipeline, so when assigning the buffers you should know what data you'll need later.
	*/

	/*DRAWBUFFERS:012*/

	//this is the scene color
	gl_FragData[0] = texture2D(tex, texcoord.st) * color;

	//write normals to a buffer to be reused later, doing *0.5+0.5 to them because they are in -1 to 1 range but buffers cant store negative values
	gl_FragData[1] = vec4(normal*0.5+0.5, 1.0);

	//write lightmaps to a buffer because we wanna use them later
	gl_FragData[2] = vec4(lmcoord.xy, 0.0, 1.0);
}