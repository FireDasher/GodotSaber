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

vec2 spheremap_uv(vec3 dir) {
    dir = normalize(dir);
    float u = atan(dir.z, dir.x) / (2.0 * PI) + 0.5;
    float v = asin(clamp(dir.y, -1.0, 1.0)) / PI + 0.5;
    return vec2(u, v);
}

void fragment() {
	if (cuttedness < 0.0) discard;
	//ALBEDO = vec3(UV, 0.0);
	//// Creating the arrow in the shader makes cutting easier
	vec2 diff = UV-0.5;
	if (FRONT_FACING && (is_dot ? diff.x*diff.x+diff.y*diff.y < 0.15 : (diff.y-0.25 > abs(diff.x*0.3)))){
		ALBEDO = vec3(2.0);
		//EMISSION = vec3(2.0);
	} else {
		vec3 dir = reflect(-VIEW, NORMAL);
		ALBEDO = texture(reflection, dir).rgb * color;
		//METALLIC = 1.0;
		//ROUGHNESS = 0.3;
	}
	ALBEDO += vec3( smoothstep(0.05, 0.04, cuttedness) );
}
