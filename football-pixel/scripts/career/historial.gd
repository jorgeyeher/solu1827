extends Control

@onready var lbl_titulo      = $Margin/VBox/LblTitulo
@onready var tab_bar         = $Margin/VBox/TabBar
@onready var contenedor      = $Margin/VBox/Scroll/Contenedor
@onready var btn_volver      = $Margin/VBox/BtnVolver

var tab_actual := 0
var font_pixel = preload("res://fonts/PressStart2P-Regular.ttf")

func _ready() -> void:
	configurar_estilos()
	btn_volver.pressed.connect(_on_volver)
	tab_bar.tab_changed.connect(_on_tab_cambio)
	lbl_titulo.text = "Historial — %s" % GameManager.nombre_equipo
	_mostrar_tab(0)

func _on_tab_cambio(idx: int) -> void:
	tab_actual = idx
	_mostrar_tab(idx)

func _mostrar_tab(idx: int) -> void:
	for hijo in contenedor.get_children():
		hijo.queue_free()
	match idx:
		0: _mostrar_resultados()
		1: _mostrar_temporadas()
		2: _mostrar_goleadores()
		3: _mostrar_campeones()

func _mostrar_resultados() -> void:
	var equipo_id = GameManager.equipo_jugador_id
	var historial = HistoryService.get_historial_club(equipo_id, 30)
	if historial.is_empty():
		_add_lbl("Sin resultados aún.", Color("aaaaaa"))
		return
	
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 8)
	contenedor.add_child(grid)
	
	for p in historial:
		var resultado := HistoryService.get_resultado_para_equipo(p, equipo_id)
		var color     := _color_resultado(resultado)
		
		# Torneo y Jornada
		_add_lbl_to_grid(grid, "T%s J%s" % [str(p.get("temporada", "")), str(p.get("jornada", ""))], Color("90a4ae"), 10)
		# Local
		_add_lbl_to_grid(grid, str(p.get("local_nombre", "")), Color.WHITE if p.get("condicion") == "local" else Color("b0bec5"), 12, HORIZONTAL_ALIGNMENT_RIGHT)
		# Resultado
		var res_lbl = _add_lbl_to_grid(grid, "%d - %d" % [int(p.get("goles_local", 0)), int(p.get("goles_visita", 0))], color, 14, HORIZONTAL_ALIGNMENT_CENTER)
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", make_style(color.darkened(0.6), 4, color, 1))
		res_lbl.get_parent().remove_child(res_lbl)
		panel.add_child(res_lbl)
		grid.add_child(panel)
		
		# Visitante
		_add_lbl_to_grid(grid, str(p.get("visita_nombre", "")), Color.WHITE if p.get("condicion") == "visitante" else Color("b0bec5"), 12)

func _mostrar_temporadas() -> void:
	var equipo_id = GameManager.equipo_jugador_id
	var stats = HistoryService.get_stats_club_por_temporada(equipo_id)
	if stats.is_empty():
		_add_lbl("Sin datos de temporadas.", Color("aaaaaa"))
		return
		
	var grid = GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	contenedor.add_child(grid)
	
	var headers = ["TEMP", "LIGA", "PJ", "V", "E", "D", "GF", "GC", "PTS"]
	for h in headers:
		_add_lbl_to_grid(grid, h, Color("a7ef73"), 10, HORIZONTAL_ALIGNMENT_CENTER)

	for s in stats:
		_add_lbl_to_grid(grid, str(s.get("temporada","")), Color.WHITE, 12, HORIZONTAL_ALIGNMENT_CENTER)
		_add_lbl_to_grid(grid, str(s.get("liga","")), Color.WHITE, 10, HORIZONTAL_ALIGNMENT_LEFT)
		for key in ["pj", "v", "empates", "d", "gf", "gc", "pts"]:
			_add_lbl_to_grid(grid, str(s.get(key, 0)), Color("b0bec5"), 12, HORIZONTAL_ALIGNMENT_CENTER)

func _mostrar_goleadores() -> void:
	var torneo_id := GameManager.torneo_activo_id
	if torneo_id == 0:
		var rows = DatabaseManager.fetch_rows(
			"SELECT liga_id FROM equipos WHERE id = %d" % GameManager.equipo_jugador_id)
		if not rows.is_empty():
			torneo_id = int(rows[0]["liga_id"])
	var temporada := GameManager.temporada_actual
	var lista = HistoryService.get_top_goleadores(torneo_id, temporada, 15)
	if lista.is_empty():
		_add_lbl("Sin goleadores aún.", Color("aaaaaa"))
		return
		
	_add_lbl("GOLEADORES — Temporada %d" % temporada, Color("a7ef73"))
	
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 15)
	grid.add_theme_constant_override("v_separation", 6)
	contenedor.add_child(grid)
	
	_add_lbl_to_grid(grid, "#", Color("a7ef73"), 10)
	_add_lbl_to_grid(grid, "JUGADOR", Color("a7ef73"), 10)
	_add_lbl_to_grid(grid, "EQUIPO", Color("a7ef73"), 10)
	_add_lbl_to_grid(grid, "GOLES", Color("a7ef73"), 10)
	_add_lbl_to_grid(grid, "ASISTENCIAS", Color("a7ef73"), 10)

	var pos := 1
	for g in lista:
		_add_lbl_to_grid(grid, str(pos), Color.WHITE, 12, HORIZONTAL_ALIGNMENT_CENTER)
		_add_lbl_to_grid(grid, str(g.get("nombre","")), Color.WHITE, 12)
		_add_lbl_to_grid(grid, str(g.get("equipo","")), Color("b0bec5"), 10)
		_add_lbl_to_grid(grid, str(g.get("goles",0)), Color("c0ff5b"), 12, HORIZONTAL_ALIGNMENT_CENTER)
		_add_lbl_to_grid(grid, str(g.get("asistencias",0)), Color("b0bec5"), 12, HORIZONTAL_ALIGNMENT_CENTER)
		pos += 1

func _mostrar_campeones() -> void:
	var lista = HistoryService.get_campeones()
	if lista.is_empty():
		_add_lbl("Aún no hay temporadas finalizadas.", Color("aaaaaa"))
		return
	_add_lbl("CAMPEONES HISTÓRICOS", Color("ffb733"))
	for c in lista:
		var texto := "T%s — %s — %s" % [
			str(c.get("temporada","")),
			str(c.get("liga","")),
			str(c.get("campeon",""))]
		_add_lbl(texto, Color("ffd54f"))

func _add_lbl(texto: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = texto
	lbl.add_theme_font_override("font", font_pixel)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	contenedor.add_child(lbl)

func _add_lbl_to_grid(grid: GridContainer, texto: String, color: Color, size: int = 12, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl = Label.new()
	lbl.text = texto
	lbl.add_theme_font_override("font", font_pixel)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grid.add_child(lbl)
	return lbl

func _color_resultado(res: String) -> Color:
	match res:
		"victoria": return Color("a7ef73")
		"empate":   return Color("90a4ae")
		_:          return Color("ef5350")

func _on_volver() -> void:
	get_tree().change_scene_to_file("res://scenes/career/submenu_club.tscn")

func configurar_estilos() -> void:
	apply_button_theme(btn_volver, Color("1d2f18"), Color("274121"), Color("12210f"), Color("f7fff5"), Color("35512f"))
	lbl_titulo.add_theme_font_override("font", font_pixel)
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	lbl_titulo.add_theme_color_override("font_color", Color("a7ef73"))

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
