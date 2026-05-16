shader_type spatial;

uniform vec3 color : source_color = vec3(1.0, 0.0, 0.0);
render_mode unshaded, blend_add, cull_disabled;

void fragment() {
	float v = 4.0 * pow(1.0 - dot(NORMAL, VIEW), 4.0);
	
	ALBEDO = color + v*vec3(4.0);
}