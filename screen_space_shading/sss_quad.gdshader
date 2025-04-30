shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform sampler2D gradient: source_color, repeat_disable, hint_default_transparent;
uniform float fog_intensity:  hint_range(0.0, 1.0);
uniform float fog_amount: hint_range(0.0, 1.0);

uniform sampler2D screen_tex : hint_screen_texture, source_color, repeat_disable, filter_nearest;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;

void vertex() {
	POSITION = vec4(2.0 * VERTEX.xy, 1.0, 1.0);
    //g_q_size = getQuantizeSize(CANVAS_MATRIX);
    //g_model_matrix = MODEL_MATRIX;
    //g_texture_size = 1. / TEXTURE_PIXEL_SIZE;
    //g_vertex = VERTEX;
    //g_flat_vertex = VERTEX;
}

void fragment() {
	//ALBEDO = texture(depth_tex, SCREEN_UV).rrr;
	//ALBEDO.rgb = texture(color_input, SCREEN_UV).rgb * vec3(0.0, 1.0, 1.0);
	vec4 original = texture(screen_tex, SCREEN_UV);

	float depth = texture(depth_tex, SCREEN_UV).x;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	#endif
	vec4 view = INV_PROJECTION_MATRIX* vec4(ndc, 1.0);
	view.xyz /= view.w;
	depth = -view.z;
	//ALBEDO = vec3(depth);

	float fog = depth * fog_amount * 0.1;

	//ALBEDO = vec3(float((depth > 2000.0)));
	vec4 fog_color = texture(gradient, vec2(fog, 0.0));
	if (depth > 3000.0) {
		ALBEDO = original.rgb;
	} else {
		if (depth > 0.0)
			ALBEDO =  mix(original.rgb, fog_color.rgb, fog_color.a * fog_intensity);
		else
			ALBEDO = original.rgb;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
