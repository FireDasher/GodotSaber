shader_type spatial;
render_mode unshaded, cull_disabled;

uniform samplerCube reflection: source_color, filter_linear_mipmap;
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
		
		// Blur code based on a renderdoc decompilation
		float dist = length(VERTEX); // aka w2.x
		float fresnel = (0.9 - dot(world_normal, world_view)) * 2.0 + max(0.0, dist - 5.0) * 0.03; // aka w3.x
		float lod = 1.0 + (-0.95 + fresnel) + clamp(dist * 0.01 - 0.3, 0.0, 1.0);
		lod = lod * (-lod * 0.7 + 1.7) * 6.0;
		
		ALBEDO = textureLod(reflection, dir, lod).rgb * color;
	}
	
	ALBEDO += vec3( smoothstep(0.05, 0.04, cuttedness) );
}