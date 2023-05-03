shader_type canvas_item;
render_mode unshaded;

uniform vec2 start_position = vec2(0.5);
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float progress : hint_range(0.0, 1.0);
uniform vec4 default_color : source_color = vec4(1,1,1,1);
//sake color
uniform vec4 detect_sake_color : source_color = vec4(0.627451, 0.12549, 0.941176, 0.5);

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	vec2 adjusted_uv = (UV - start_position) * 2.0;
	float dist = length(adjusted_uv);
	vec4 color = step(progress, dist) > 0.0 ? default_color : detect_sake_color;
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	COLOR *= c * color * texture(TEXTURE, UV);
}
