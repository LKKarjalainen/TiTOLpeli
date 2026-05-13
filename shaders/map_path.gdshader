shader_type canvas_item;

uniform vec4 color : source_color;

const float THICKNESS = 0.1; 

void fragment() {
	COLOR.rgb = (1.0 - smoothstep(0.5 - THICKNESS - 0.005, 0.5 - THICKNESS, length(0.5 - UV.y))) * color.rgb;
	COLOR.a = 1.0 - smoothstep(0.5 - 0.005, 0.5, length(UV.y - 0.5));
}
