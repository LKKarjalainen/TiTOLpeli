shader_type canvas_item;

uniform vec4 color : source_color;

const float THICKNESS = 0.1; 

float circle(vec2 position, float radius, float feather) {
	return smoothstep(radius, radius + feather, length(position - vec2(0.5)));
}

void fragment() {
	COLOR = (1.0 - circle(UV, 0.5 - THICKNESS - 0.005, 0.005)) * color;
	COLOR.a = 1.0 - circle(UV, 0.5 - 0.005, 0.005);
}
