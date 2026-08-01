extends Control

var visuals := {
	"camiseta": "Rojo",
	"shorts": "Blanco",
	"calcetas": "Azul",
	"patron_escudo": "Solido",
	"escudo_primario": "Azul",
	"escudo_secundario": "Blanco"
}

const COLORS := {
	"Blanco": Color("f4f1de"),
	"Negro": Color("1f2933"),
	"Rojo": Color("d1495b"),
	"Azul": Color("245ca6"),
	"Verde": Color("3a7d44"),
	"Amarillo": Color("f4b942"),
	"Naranja": Color("f28f3b"),
	"Morado": Color("6c4ab6")
}

func set_visuals(data: Dictionary) -> void:
	for key in data.keys():
		visuals[key] = data[key]
	queue_redraw()

func _draw() -> void:
	var area = get_rect()
	draw_rect(area, Color("101512"))

	var camiseta = get_color("camiseta")
	var shorts = get_color("shorts")
	var calcetas = get_color("calcetas")
	var escudo_primario = get_color("escudo_primario")
	var escudo_secundario = get_color("escudo_secundario")

	var center_x = area.size.x * 0.32
	var top_y = area.size.y * 0.22

	draw_rect(Rect2(center_x - 34.0, top_y + 18.0, 68.0, 78.0), camiseta)
	draw_polygon(
		PackedVector2Array([
			Vector2(center_x - 34.0, top_y + 18.0),
			Vector2(center_x - 66.0, top_y + 34.0),
			Vector2(center_x - 52.0, top_y + 72.0),
			Vector2(center_x - 34.0, top_y + 58.0)
		]),
		PackedColorArray([camiseta])
	)
	draw_polygon(
		PackedVector2Array([
			Vector2(center_x + 34.0, top_y + 18.0),
			Vector2(center_x + 66.0, top_y + 34.0),
			Vector2(center_x + 52.0, top_y + 72.0),
			Vector2(center_x + 34.0, top_y + 58.0)
		]),
		PackedColorArray([camiseta])
	)
	draw_rect(Rect2(center_x - 18.0, top_y, 36.0, 22.0), camiseta.darkened(0.1))
	draw_line(Vector2(center_x, top_y), Vector2(center_x - 10.0, top_y + 18.0), Color.WHITE, 2.0)
	draw_line(Vector2(center_x, top_y), Vector2(center_x + 10.0, top_y + 18.0), Color.WHITE, 2.0)

	draw_rect(Rect2(center_x - 30.0, top_y + 98.0, 26.0, 34.0), shorts)
	draw_rect(Rect2(center_x + 4.0, top_y + 98.0, 26.0, 34.0), shorts)
	draw_rect(Rect2(center_x - 24.0, top_y + 132.0, 10.0, 48.0), calcetas)
	draw_rect(Rect2(center_x + 14.0, top_y + 132.0, 10.0, 48.0), calcetas)

	draw_shield(Vector2(area.size.x * 0.73, area.size.y * 0.5), escudo_primario, escudo_secundario)

func draw_shield(center: Vector2, primary: Color, secondary: Color) -> void:
	var shield_points = PackedVector2Array([
		center + Vector2(0.0, -74.0),
		center + Vector2(56.0, -46.0),
		center + Vector2(46.0, 26.0),
		center + Vector2(0.0, 82.0),
		center + Vector2(-46.0, 26.0),
		center + Vector2(-56.0, -46.0)
	])

	draw_polygon(shield_points, PackedColorArray([primary]))
	draw_polyline(shield_points + PackedVector2Array([shield_points[0]]), Color.WHITE, 4.0)

	match str(visuals.get("patron_escudo", "Solido")):
		"Franja vertical":
			draw_rect(Rect2(center.x - 12.0, center.y - 60.0, 24.0, 118.0), secondary)
		"Franja horizontal":
			draw_rect(Rect2(center.x - 44.0, center.y - 10.0, 88.0, 24.0), secondary)
		"Diagonal":
			draw_polygon(
				PackedVector2Array([
					center + Vector2(-44.0, 20.0),
					center + Vector2(-24.0, 36.0),
					center + Vector2(46.0, -34.0),
					center + Vector2(32.0, -52.0)
				]),
				PackedColorArray([secondary])
			)
		"Mitad":
			draw_polygon(
				PackedVector2Array([
					center + Vector2(0.0, -74.0),
					center + Vector2(56.0, -46.0),
					center + Vector2(46.0, 26.0),
					center + Vector2(0.0, 82.0)
				]),
				PackedColorArray([secondary])
			)
		"Cruz":
			draw_rect(Rect2(center.x - 10.0, center.y - 56.0, 20.0, 102.0), secondary)
			draw_rect(Rect2(center.x - 40.0, center.y - 6.0, 80.0, 20.0), secondary)

	draw_circle(center, 12.0, Color.WHITE)
	draw_circle(center, 7.0, primary.darkened(0.3))

func get_color(key: String) -> Color:
	return COLORS.get(str(visuals.get(key, "Blanco")), Color.WHITE)
