shader_type canvas_item;
// Le grain de la pièce — ce qui fait « jeu vidéo » sans toucher à la direction
// artistique (issue #54, piste 1). Le thème clair « post-it & feutre » du Lot 1
// reste intact : on n'ajoute qu'une matière et une vignette.
//
// Procédural, donc zéro asset et zéro octet : c'est exactement ce qui donne sa
// texture à un Balatro, dont le rendu n'est presque pas fait d'images.

uniform float grain_strength : hint_range(0.0, 0.2) = 0.055;
uniform float grain_scale = 620.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.34;
uniform float vignette_radius : hint_range(0.2, 1.4) = 0.92;
// Le grain respire très lentement : à vitesse élevée il devient du bruit de
// télévision et fatigue. On veut une surface vivante, pas un écran cassé.
uniform float drift_speed : hint_range(0.0, 4.0) = 0.55;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * grain_scale + floor(TIME * drift_speed) * 13.0);
	float noise = hash(cell) - 0.5;

	// Vignette douce : elle recentre le regard sur le plateau sans assombrir
	// les papiers du mur, qui portent l'information.
	vec2 centered = (UV - 0.5) * vec2(1.0, 0.72);
	float vignette = smoothstep(vignette_radius, 0.28, length(centered));

	COLOR = vec4(vec3(0.0), 0.0);
	COLOR.rgb = vec3(noise > 0.0 ? 1.0 : 0.0);
	COLOR.a = abs(noise) * grain_strength * 2.0 + (1.0 - vignette) * vignette_strength * 0.5;
	COLOR.rgb = mix(vec3(0.09, 0.07, 0.05), COLOR.rgb, step(0.0, noise));
}
