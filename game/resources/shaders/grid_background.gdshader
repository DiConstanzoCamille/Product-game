shader_type canvas_item;
// Fond des écrans de phase, direction « Post-it & Feutre » (docs/proposition-ui-interface.md
// §6) : blanc cassé et lignes réglées à peine visibles, comme une page de cahier
// ou un tableau blanc. En espace écran, pour un rendu cohérent quel que soit le
// Control. Avant la refonte UI ce shader dessinait un quadrillage sombre (repris
// de landing/css/style.css) ; `vertical_rules` permet de le retrouver.

uniform vec4 bg_color : source_color = vec4(0.956863, 0.964706, 0.952941, 1.0);
uniform vec4 line_color : source_color = vec4(0.352941, 0.411765, 0.509804, 0.06);
uniform float cell_size : hint_range(8.0, 256.0) = 47.0;
uniform float line_width : hint_range(0.5, 4.0) = 1.0;
uniform bool vertical_rules = false;

void fragment() {
	vec2 grid = mod(FRAGCOORD.xy, cell_size);
	float line = step(grid.y, line_width);
	if (vertical_rules) {
		line = clamp(line + step(grid.x, line_width), 0.0, 1.0);
	}
	vec3 col = mix(bg_color.rgb, line_color.rgb, line * line_color.a);
	COLOR = vec4(col, 1.0);
}
