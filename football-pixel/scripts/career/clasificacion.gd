extends Control

@onready var lbl_titulo     = $Margin/VBox/LblTitulo
@onready var lbl_equipo_jug = $Margin/VBox/LblEquipoJug
@onready var tabla_grid     = $Margin/VBox/TablaScroll/TablaGrid
@onready var btn_volver     = $Margin/VBox/BtnVolver

var tab_actual := 0
var font_pixel = preload("res://fonts/PressStart2P-Regular.ttf")

func _ready() -> void:
	configurar_estilos()
	btn_volver.pressed.connect(_on_volver)
	cargar_clasificacion()

func cargar_clasificacion() -> void:
	var torneo_id := GameManager.torneo_activo_id
	var temporada := GameManager.temporada_actual
	
	# Detectar liga si torneo_id es 0
	if torneo_id == 0:
		var rows = DatabaseManager.fetch_rows(
			"SELECT liga_id FROM equipos WHERE id = %d" % GameManager.equipo_jugador_id)
		if not rows.is_empty():
			torneo_id = int(rows[0]["liga_id"])
	
	# Nombre de la liga
	var liga_rows = DatabaseManager.fetch_rows("SELECT nombre FROM ligas WHERE id = %d" % torneo_id)
	var liga_nombre := "Liga" if liga_rows.is_empty() else str(liga_rows[0]["nombre"])
	lbl_titulo.text = "%s — Temporada %d" % [liga_nombre, temporada]
	lbl_equipo_jug.text = GameManager.nombre_equipo
	
	var standings = StandingsService.get_standings(torneo_id, temporada)
	_construir_tabla(standings)

func _construir_tabla(standings: Array) -> void:
	for hijo in tabla_grid.get_children():
		hijo.queue_free()
	
	# Cabecera
	var headers = ["#", "EQUIPO", "PJ", "V", "E", "D", "GF", "GC", "DG", "PTS"]
	for col in headers:
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", make_style(Color("162414"), 0, Color("35512f"), 2))
		var lbl = Label.new()
		lbl.text = col
		lbl.add_theme_font_override("font", font_pixel)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color("a7ef73"))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(lbl)
		tabla_grid.add_child(panel)
	
	# Filas
	var pos := 1
	for row in standings:
		var es_jugador := (int(row.get("equipo_id", 0)) == GameManager.equipo_jugador_id)
		var color_fondo := Color("2e7d32") if es_jugador else (Color("111419") if pos % 2 == 0 else Color("1a1e25"))
		
		var valores = [
			str(pos),
			str(row.get("nombre", "")).left(16),
			str(row.get("pj", 0)),
			str(row.get("v", 0)),
			str(row.get("empates", 0)),
			str(row.get("d", 0)),
			str(row.get("gf", 0)),
			str(row.get("gc", 0)),
			str(row.get("dg", 0)),
			str(row.get("pts", 0))
		]
		
		for i in range(valores.size()):
			var lbl = Label.new()
			lbl.text = valores[i]
			lbl.add_theme_font_override("font", font_pixel)
			lbl.add_theme_font_size_override("font_size", 10)
			lbl.add_theme_color_override("font_color",
				Color("ffffff") if es_jugador else Color("b0bec5"))
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			if i == 1:
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				
			var panel = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = color_fondo
			style.border_color = Color("35512f")
			style.set_border_width_all(1)
			panel.add_theme_stylebox_override("panel", style)
			panel.add_child(lbl)
			tabla_grid.add_child(panel)
		
		pos += 1

func _on_volver() -> void:
	get_tree().change_scene_to_file("res://scenes/career/submenu_club.tscn")

func configurar_estilos() -> void:
	apply_button_theme(btn_volver, Color("1d2f18"), Color("274121"), Color("12210f"), Color("f7fff5"), Color("35512f"))
	lbl_titulo.add_theme_font_override("font", font_pixel)
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	lbl_titulo.add_theme_color_override("font_color", Color("a7ef73"))
	
	lbl_equipo_jug.add_theme_font_override("font", font_pixel)
	lbl_equipo_jug.add_theme_font_size_override("font_size", 14)
	lbl_equipo_jug.add_theme_color_override("font_color", Color("ffffff"))

func apply_button_theme(b: Button, n: Color, h: Color, p: Color, f: Color, brd: Color) -> void:
	b.add_theme_stylebox_override("normal",  make_style(n, 8, brd, 2))
	b.add_theme_stylebox_override("hover",   make_style(h, 8, brd, 2))
	b.add_theme_stylebox_override("pressed", make_style(p, 8, brd, 2))
	b.add_theme_color_override("font_color",         f)
	b.add_theme_color_override("font_hover_color",   f)
	b.add_theme_color_override("font_pressed_color", f)

func make_style(c: Color, r: int = 0, b: Color = Color.TRANSPARENT, w: int = 0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = c; s.border_color = b
	s.set_border_width_all(w); s.set_corner_radius_all(r)
	return s
