shader_type canvas_item;

uniform float stripe_width : hint_range(0.01, 2.0) = 0.6;
uniform vec4 stripe_color : source_color = vec4(0.1803921610117, 0.54509806632996, 0.34117648005486, 1.0);
uniform vec4 background_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float radius_scale : hint_range(0.01, 0.2) = 0.12;

void fragment() {
	vec2 uv = UV;
	float distance_from_origin = length(uv);
	float final_pattern = mod(distance_from_origin * radius_scale, stripe_width * 2.0) < stripe_width ? 1.0 : 0.0;
	COLOR = mix(stripe_color, background_color, final_pattern);
}