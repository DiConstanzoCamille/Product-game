shader_type canvas_item;
// La dalle du poste de travail — piste 3 : le monde reste clair et papier,
// **l'écran est le seul endroit saturé et animé du jeu**. La fiction le
// justifie : le bureau est terne, le logiciel brille.
//
// Tout est procédural. `intensity` pilote l'ensemble d'un seul curseur, pour
// qu'on puisse trancher « jusqu'où on pousse » sans retoucher six valeurs —
// et pour que le réglage finisse dans balance.json, pas dans un script.

uniform float intensity : hint_range(0.0, 1.0) = 0.6;
uniform vec4 tint : source_color = vec4(0.18, 0.62, 0.86, 1.0);
uniform float scanline_count = 210.0;
uniform float curvature : hint_range(0.0, 0.5) = 0.12;
// On relit ce qui a déjà été peint sous la dalle : c'est ce qui permet une
// vraie saturation et un vrai bombé, et pas seulement un calque posé dessus.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

void fragment() {
	vec2 uv = UV;

	// Bombé de dalle : deux pixels suffisent à faire lire « écran » plutôt que
	// « rectangle ». Au-delà, ça devient une borne d'arcade.
	vec2 centered = uv * 2.0 - 1.0;
	centered *= 1.0 + curvature * intensity * dot(centered.yx, centered.yx) * 0.12;
	uv = centered * 0.5 + 0.5;

	vec2 screen_uv = SCREEN_UV + (uv - UV) * (1.0 / max(SCREEN_PIXEL_SIZE.x, 0.00001)) * SCREEN_PIXEL_SIZE.x;
	vec4 base = texture(screen_tex, screen_uv);

	// Scanlines : l'ingrédient le moins cher et le plus reconnaissable.
	float scan = 1.0 - 0.16 * intensity * (0.5 + 0.5 * sin(uv.y * scanline_count * 3.14159));
	base.rgb *= scan;

	// Halo depuis le centre, teinté : c'est lui qui « allume » la dalle.
	float glow = smoothstep(1.15, 0.1, length(centered));
	base.rgb += tint.rgb * glow * 0.22 * intensity;

	// Saturation : le contraste avec le papier terne vient surtout de là.
	float luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	base.rgb = mix(vec3(luma), base.rgb, 1.0 + 0.7 * intensity);

	// Souffle très lent, pour que la dalle ne soit jamais tout à fait figée.
	base.rgb *= 1.0 + 0.012 * intensity * sin(TIME * 1.7);

	// Les bords hors dalle après le bombé ne doivent pas montrer de bavure.
	float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	COLOR = vec4(base.rgb, inside);
}
