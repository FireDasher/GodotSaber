shader_type spatial;
render_mode unshaded;

uniform vec3 color : source_color = vec3(1.0, 0.0, 0.0);

void fragment() {
	float v = pow(1.0 - dot(NORMAL, VIEW), 2.0);
	
	ALBEDO = color * (v*0.9+0.1);
}