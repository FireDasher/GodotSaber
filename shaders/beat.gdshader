shader_type spatial;
render_mode unshaded, cull_disabled;

uniform samplerCube reflection: source_color;
instance uniform vec3 color : source_color = vec3(1.0, 0.0, 0.0);
instance uniform bool is_dot = false;
instance uniform vec4 cut_plane = vec4(0.0, 1.0, 0.0, -1.0);

varying float cuttedness;

void vertex() {
	cuttedness = dot(VERTEX, cut_plane.xyz) - cut_plane.w;
}

void fragment() {
	if (cuttedness < 0.0) discard;
	//// Creating the arrow in the shader makes cutting easier
	vec2 diff = UV-0.5;
	if (FRONT_FACING && (is_dot ? diff.x*diff.x+diff.y*diff.y < 0.15 : (diff.y-0.25 > abs(diff.x*0.3)))){
		ALBEDO = vec3(2.0);
	} else {
		vec3 world_view = mat3(INV_VIEW_MATRIX) * VIEW;
		vec3 world_normal = mat3(INV_VIEW_MATRIX) * NORMAL;
		vec3 dir = reflect(-world_view, world_normal);
		
		// calculate blur based on a renderdoc decompilation
		float dist=length(VERTEX);
	    float ndotv=clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0);
	    float w3=clamp(2.0*(0.9-ndotv)+0.03*max(0.0,dist-5.0),0.0,1.0);
	    float d=clamp(dist*0.01-0.3,0.0,1.0);
	    float x=0.05+w3+d;
	    float lod=max(6.0*x*(1.7-0.7*x),0.0);
		
		ALBEDO = textureLod(reflection, dir, lod).rgb * color;
	}
	
	ALBEDO += vec3( smoothstep(0.05, 0.04, cuttedness) );
}