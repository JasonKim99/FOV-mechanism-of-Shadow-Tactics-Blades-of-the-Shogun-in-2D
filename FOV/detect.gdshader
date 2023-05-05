shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 fov_color : source_color = vec4(0.627451, 0.12549, 0.941176, 0.5882352941);
uniform vec2 fov_uv_pos ;
uniform float radius : hint_range(0.0, 10000.0);

void fragment() {
    vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	// 因为屏幕的高宽比不同，不除以SCREEN_PIXEL_SIZE，则会变成椭圆
	float dist = length(SCREEN_UV / SCREEN_PIXEL_SIZE - fov_uv_pos / SCREEN_PIXEL_SIZE) ;
	if (dist < radius) {
		c.rgb = fov_color.rgb;
	}
	
    if (c.a > 0.0001) {
        c.rgb /= c.a;
    }

    COLOR *= c;
}
