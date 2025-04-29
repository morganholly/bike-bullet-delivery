shader_type canvas_item;
// This file relies on a dither shader include file, listed further down.
// The paths must match your file's location.
#include "res://screen_space_shading/dither.gdshaderinc"
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

//uniform int pixel_size : hint_range(1, 64) = 4; // Pixel size
//uniform vec2 screen_size = vec2(1280.0, 720.0); // Screen size (set manually)

void vertex() {
	g_q_size = getQuantizeSize(CANVAS_MATRIX);
	g_model_matrix = MODEL_MATRIX;
	g_world_to_clip = SCREEN_MATRIX * CANVAS_MATRIX;
	g_vertex = VERTEX;
}

void fragment() {
	//Pixel coordinates in screen space
	//vec2 pixel_coords = floor(FRAGCOORD.xy / float(pixel_size)) * float(pixel_size);
	// Convert pixel coordinates to UVs for screen texture
	//vec2 uv = pixel_coords / screen_size;
	// Get color from texture screen
	//COLOR = texture(SCREEN_TEXTURE, uv);
	COLOR = ditherScreen(SCREEN_TEXTURE, SCREEN_UV, g_vertex);
}