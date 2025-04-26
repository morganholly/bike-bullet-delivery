float remap(float x, float lo1, float hi1, float lo2, float hi2) {
	return ((x - lo1) * (hi2 - lo2)) / (hi1 - lo1) + lo2;
}

vec3 matrix_vec3(mat4 Mat, vec3 Vec) {
	return (Mat * vec4(Vec, 0.0)).xyz;
}

float bph_intensity(vec3 view, vec3 light, vec3 normal, float sharpness) {
	vec3 halfway = normalize(light + view);
	//if (dot(light, normal) > 0.0) {
	float front_facing = max(remap(dot(normal, light), -0.33333333333333333, 1.0, 0.0, 1.0), 0.0);
		return pow(max(dot(normal, halfway), 0.0), sharpness) * front_facing * front_facing;
		//return clamp(dot(halfway, normal), 0.0, 1.0);
	//} else {
		//return 0.0;
	//}
}

float bph_intensity_clip_first(vec3 view, vec3 light, vec3 normal, float clip, float sharpness) {
	vec3 halfway = normalize(light + view);
	//if (dot(light, normal) > 0.0) {
	float front_facing = max(remap(dot(normal, light), -0.33333333333333333, 1.0, 0.0, 1.0), 0.0);
		return pow(max(remap(dot(normal, halfway), clip, 1.0, 0.0, 1.0), 0.0), sharpness) * front_facing * front_facing;
		//return clamp(dot(halfway, normal), 0.0, 1.0);
	//} else {
		//return 0.0;
	//}
}

float bph_intensity_dual(vec3 view, vec3 light, vec3 normal, float s1, float s2) {
	vec3 halfway = normalize(light + view);
	//if (dot(light, normal) > 0.0) {
	float front_facing = max(remap(dot(normal, light), -0.33333333333333333, 1.0, 0.0, 1.0), 0.0);
		return (pow(max(dot(normal, halfway), 0.0), s1) * 0.3 + 0.7 * pow(max(dot(normal, halfway), 0.0), s2)) * front_facing * front_facing;
		//return clamp(dot(halfway, normal), 0.0, 1.0);
	//} else {
		//return 0.0;
	//}
}

float lambertian_simple_roughness(vec3 light, vec3 normal, float roughness) {
	float rough = clamp(roughness, 0.0, 1.0);
	return pow(max(0.0, remap(dot(normal, light), -1.0 * rough + 0.5, 1.0, 0.0, 1.0)), 1.5 + 2.5 * (1.0 - rough));
}