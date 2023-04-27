shader_type canvas_item;

uniform float stripe_width : hint_range(0.01, 1.0) = 0.05;
uniform vec4 stripe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 background_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float radius_scale : hint_range(0.01, 0.2) = 0.1;

void fragment() {
	vec2 uv = UV;
	vec2 pixel_size = vec2(1.0) / vec2(texture(TEXTURE, vec2(0.5)).xy);
//	uv = 2.0 * (uv - vec2(0.5, 0.5));
	float distance_from_center = length(uv);

	float stripe_pattern = mod(distance_from_center * radius_scale, stripe_width * 2.0) < stripe_width ? 1.0 : 0.0;

	COLOR = mix(stripe_color, background_color, stripe_pattern);
}
