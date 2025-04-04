shader_type spatial;
render_mode unshaded, fog_disabled;

#include "res://screen_space_shading/dither.gdshaderinc"

uniform sampler2D color_input : source_color, hint_screen_texture;

void vertex() {
	POSITION = vec4(2.0 * VERTEX.xy, 1.0, 1.0);
    //g_q_size = getQuantizeSize(CANVAS_MATRIX);
    //g_model_matrix = MODEL_MATRIX;
    //g_texture_size = 1. / TEXTURE_PIXEL_SIZE;
    //g_vertex = VERTEX;
    //g_flat_vertex = VERTEX;
}

void fragment() {
	ALBEDO.rgb = texture(color_input, SCREEN_UV).rgb * vec3(0.0, 1.0, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
