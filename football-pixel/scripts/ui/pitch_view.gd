extends Control

const GRASS_A := Color("0e6b12")
const GRASS_B := Color("0a5b0f")
const LINE := Color("eaf7ea")

func _draw() -> void:
	var r = get_rect()
	var stripe_h = r.size.y / 12.0

	for i in range(12):
		var color = GRASS_A if i % 2 == 0 else GRASS_B
		draw_rect(Rect2(0, i * stripe_h, r.size.x, stripe_h + 1.0), color)

	draw_rect(r, LINE, false, 3.0)
	draw_line(Vector2(0, r.size.y * 0.5), Vector2(r.size.x, r.size.y * 0.5), LINE, 3.0)
	draw_arc(Vector2(r.size.x * 0.5, r.size.y * 0.5), 46.0, 0.0, TAU, 48, LINE, 3.0)
	draw_circle(Vector2(r.size.x * 0.5, r.size.y * 0.5), 3.0, LINE)

	draw_rect(Rect2(r.size.x * 0.2, r.size.y * 0.74, r.size.x * 0.6, r.size.y * 0.18), LINE, false, 3.0)
	draw_rect(Rect2(r.size.x * 0.32, r.size.y * 0.82, r.size.x * 0.36, r.size.y * 0.10), LINE, false, 3.0)
	draw_rect(Rect2(r.size.x * 0.44, r.size.y * 0.92, r.size.x * 0.12, r.size.y * 0.03), LINE, false, 3.0)
	draw_arc(Vector2(r.size.x * 0.5, r.size.y * 0.74), 34.0, PI * 0.08, PI * 0.92, 24, LINE, 3.0)

	draw_rect(Rect2(r.size.x * 0.2, r.size.y * 0.08, r.size.x * 0.6, r.size.y * 0.18), LINE, false, 3.0)
	draw_rect(Rect2(r.size.x * 0.32, r.size.y * 0.08, r.size.x * 0.36, r.size.y * 0.10), LINE, false, 3.0)
	draw_rect(Rect2(r.size.x * 0.44, r.size.y * 0.05, r.size.x * 0.12, r.size.y * 0.03), LINE, false, 3.0)
	draw_arc(Vector2(r.size.x * 0.5, r.size.y * 0.26), 34.0, -PI * 0.92, -PI * 0.08, 24, LINE, 3.0)
