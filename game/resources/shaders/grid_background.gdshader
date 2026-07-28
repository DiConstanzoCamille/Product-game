shader_type canvas_item;
// Reproduit le fond quadrillé de landing/css/style.css (repeating-linear-gradient
// toutes les 48px), en espace écran pour un rendu cohérent quel que soit le Control.

uniform vec4 bg_color : source_color = vec4(0.0705882, 0.12549, 0.25098, 1.0);
uniform vec4 line_color : source_color = vec4(0.85, 0.89, 0.95, 0.05);
uniform float cell_size : hint_range(8.0, 256.0) = 48.0;
uniform float line_width : hint_range(0.5, 4.0) = 1.0;

void fragment() {
	vec2 grid = mod(FRAGCOORD.xy, cell_size);
	float line = clamp(step(grid.x, line_width) + step(grid.y, line_width), 0.0, 1.0);
	vec3 col = mix(bg_color.rgb, line_color.rgb, line * line_color.a);
	COLOR = vec4(col, 1.0);
}
