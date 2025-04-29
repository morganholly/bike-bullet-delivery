shader_type canvas_item;

uniform vec4 trail_color : source_color = vec4(0.914, 0.565, 0.224, 1.0); // #E99039

void fragment() {
    // Create a vertical line
    float line_width = 0.1; // This will be scaled by the particle system
    float dist = abs(UV.x - 0.5);
    
    if (dist < line_width) {
        COLOR = trail_color;
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
} 