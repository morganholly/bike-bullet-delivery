shader_type spatial;
#include "res://textures/blinnphong.gdshaderinc"
//render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	//ALBEDO = matrix_vec3(INV_VIEW_MATRIX, VIEW);
	//ALBEDO = vec3(0.2);
}

void light() {
	////Called for every pixel for every light affecting the material.
	////Uncomment to replace the default light processing function with this one.
	//// INV_VIEW_MATRIX
	//SPECULAR_LIGHT += bph_intensity_dual(matrix_vec3(INV_VIEW_MATRIX, VIEW), matrix_vec3(INV_VIEW_MATRIX, LIGHT), matrix_vec3(INV_VIEW_MATRIX, NORMAL), 32.0, 128.0);
	//SPECULAR_LIGHT += bph_intensity(matrix_vec3(INV_VIEW_MATRIX, VIEW), matrix_vec3(INV_VIEW_MATRIX, LIGHT), matrix_vec3(INV_VIEW_MATRIX, NORMAL), 32.0);
	SPECULAR_LIGHT += vec3(0.0, 1.0, 0.0) * bph_intensity_clip_first(matrix_vec3(INV_VIEW_MATRIX, VIEW), matrix_vec3(INV_VIEW_MATRIX, LIGHT), matrix_vec3(INV_VIEW_MATRIX, NORMAL), -0.5, 32.0);
	DIFFUSE_LIGHT += vec3(1.0, 0.0, 0.0) * lambertian_simple_roughness(matrix_vec3(INV_VIEW_MATRIX, LIGHT), matrix_vec3(INV_VIEW_MATRIX, NORMAL), 1);
	//DIFFUSE_LIGHT += pow(max(0.0, dot(matrix_vec3(INV_VIEW_MATRIX, LIGHT), matrix_vec3(INV_VIEW_MATRIX, NORMAL))), 1.0);
}
