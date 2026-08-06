extends Control

@onready var lbl_temporada   = $Margin/VBox/Header/LblTemporada
@onready var lbl_jornada     = $Margin/VBox/Header/LblJornada
@onready var lbl_estado      = $Margin/VBox/LblEstado
@onready var lista_partidos  = $Margin/VBox/ListaPartidos
@onready var btn_simular     = $Margin/VBox/Botones/BtnSimular
@onready var btn_nueva_temp  = $Margin/VBox/Botones/BtnNuevaTemp
@onready var btn_volver      = $Margin/VBox/Botones/BtnVolver

var torneo_id  := 0
var temporada  := 1
var jornada    := 1

func _ready() -> void:
	configurar_estilos()
	torneo_id = GameManager.torneo_activo_id
	temporada = GameManager.temporada_actual
	
	btn_simular.pressed.connect(_on_simular)
	btn_nueva_temp.pressed.connect(_on_nueva_temporada)
	btn_volver.pressed.connect(_on_volver)
	btn_nueva_temp.visible = false
	btn_simular.visible    = false
	
	cargar_jornada()

func cargar_jornada() -> void:
	if torneo_id == 0:
		# Detectar torneo del equipo del jugador
		var rows = DatabaseManager.fetch_rows(
			"SELECT liga_id FROM equipos WHERE id = %d" % GameManager.equipo_jugador_id)
		if not rows.is_empty():
			torneo_id = int(rows[0]["liga_id"])
			GameManager.torneo_activo_id = torneo_id

	jornada = CareerService.get_current_jornada(torneo_id, temporada)
	
	lbl_temporada.text = "Temporada %d" % temporada
	
	if jornada == -1:
		lbl_jornada.text   = "Temporada finalizada"
		lbl_estado.text    = "Todos los partidos han sido jugados."
		btn_nueva_temp.visible = true
		_poblar_lista([])
		return
	
	lbl_jornada.text = "Jornada %d" % jornada
	var partidos = CareerService.get_partidos_jornada(torneo_id, temporada, jornada)
	_poblar_lista(partidos)
	
	# Verificar si el partido del jugador ya fue disputado
	var mi_partido_ok := true
	var equipo_id     := GameManager.equipo_jugador_id
	for p in partidos:
		var es_mio = (int(p["equipo_local_id"]) == equipo_id or
					  int(p["equipo_visita_id"]) == equipo_id)
		if es_mio and int(p.get("jugado", 0)) == 0:
			mi_partido_ok = false
			break
	
	if mi_partido_ok:
		# Ver si hay partidos de IA pendientes
		var pendientes_ia := false
		for p in partidos:
			var es_mio = (int(p["equipo_local_id"]) == equipo_id or
						  int(p["equipo_visita_id"]) == equipo_id)
			if not es_mio and int(p.get("jugado", 0)) == 0:
				pendientes_ia = true
				break
		
		if pendientes_ia:
			btn_simular.visible = true
			lbl_estado.text     = "Tu partido está listo. Simula los partidos de IA para avanzar."
		else:
			lbl_estado.text     = "Jornada completa. Avanza desde el botón de arriba."
	else:
		lbl_estado.text = "Juega tu partido antes de avanzar la jornada."

func _poblar_lista(partidos: Array) -> void:
	for hijo in lista_partidos.get_children():
		hijo.queue_free()
	
	for p in partidos:
		var fila = HBoxContainer.new()
		fila.add_theme_constant_override("separation", 16)
		
		var jugado   := int(p.get("jugado", 0)) == 1
		var es_mio   := (int(p.get("equipo_local_id", 0)) == GameManager.equipo_jugador_id or
						 int(p.get("equipo_visita_id", 0)) == GameManager.equipo_jugador_id)
		
		var icono = Label.new()
		icono.text = "✓" if jugado else ("🎮" if es_mio else "⏳")
		icono.add_theme_font_size_override("font_size", 20)
		icono.add_theme_color_override("font_color",
			Color("4caf50") if jugado else (Color("42a5f5") if es_mio else Color("ffb733")))
		
		var lbl = Label.new()
		var local_n  := str(p.get("local_nombre", "Local"))
		var visita_n := str(p.get("visita_nombre", "Visitante"))
		if jugado:
			lbl.text = "%s  %d - %d  %s" % [
				local_n, int(p.get("goles_local", 0)), int(p.get("goles_visita", 0)), visita_n]
		else:
			lbl.text = "%s  vs  %s" % [local_n, visita_n]
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color("f0f0f0"))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		fila.add_child(icono)
		fila.add_child(lbl)
		lista_partidos.add_child(fila)

func _on_simular() -> void:
	btn_simular.disabled = true
	lbl_estado.text      = "Simulando jornada..."
	await get_tree().process_frame
	
	var res = CareerService.advance_jornada(
		GameManager.equipo_jugador_id, torneo_id, temporada)
	
	if not res["success"]:
		lbl_estado.text      = "Error: " + res["error"]
		btn_simular.disabled = false
		return
	
	# Mostrar resultados simulados
	var texto := "Jornada %d completada.\n" % jornada
	for partido in res["partidos_simulados"]:
		texto += "  %s %d - %d %s\n" % [
			partido["local"], partido["goles_local"],
			partido["goles_visita"], partido["visita"]]
	
	lbl_estado.text = texto
	btn_simular.visible = false
	
	if res["temporada_finalizada"]:
		lbl_jornada.text   = "¡Temporada %d finalizada!" % temporada
		btn_nueva_temp.visible = true
	else:
		# Avanzar jornada en el save
		GameManager.jornada_actual += 1
		GameManager.save_game()
		await get_tree().create_timer(1.5).timeout
		cargar_jornada()

func _on_nueva_temporada() -> void:
	btn_nueva_temp.disabled = true
	lbl_estado.text = "Iniciando temporada %d..." % (temporada + 1)
	await get_tree().process_frame
	
	var res = CareerService.start_new_season(torneo_id, temporada)
	if not res["success"]:
		lbl_estado.text = "Error: " + res["error"]
		btn_nueva_temp.disabled = false
		return
	
	GameManager.temporada_actual = res["nueva_temporada"]
	GameManager.jornada_actual   = 1
	GameManager.save_game()
	
	temporada = GameManager.temporada_actual
	jornada   = 1
	lbl_estado.text = "¡Temporada %d iniciada!" % temporada
	btn_nueva_temp.visible = false
	await get_tree().create_timer(1.0).timeout
	cargar_jornada()

func _on_volver() -> void:
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/career/menu_plantilla.tscn")

# ----------------------------------------------------------------
func configurar_estilos() -> void:
	apply_button_theme(btn_simular,    Color("42a5f5"), Color("63b4f8"), Color("2e8fe1"), Color("082033"), Color("1566a8"))
	apply_button_theme(btn_nueva_temp, Color("66bb6a"), Color("81c784"), Color("4caf50"), Color("012701"), Color("1b5e20"))
	apply_button_theme(btn_volver,     Color("37474f"), Color("455a64"), Color("263238"), Color("eceff1"), Color("78909c"))
	lbl_temporada.add_theme_font_size_override("font_size", 28)
	lbl_jornada.add_theme_font_size_override("font_size", 24)
	lbl_temporada.add_theme_color_override("font_color", Color("ffb733"))
	lbl_jornada.add_theme_color_override("font_color",   Color("f0f0f0"))
	lbl_estado.add_theme_color_override("font_color",    Color("c8e6c9"))

func apply_button_theme(b: Button, n: Color, h: Color, p: Color, f: Color, brd: Color) -> void:
	b.add_theme_stylebox_override("normal",  make_style(n, 8, brd, 2))
	b.add_theme_stylebox_override("hover",   make_style(h, 8, brd, 2))
	b.add_theme_stylebox_override("pressed", make_style(p, 8, brd, 2))
	b.add_theme_color_override("font_color",          f)
	b.add_theme_color_override("font_hover_color",    f)
	b.add_theme_color_override("font_pressed_color",  f)

func make_style(c: Color, r: int = 0, b: Color = Color.TRANSPARENT, w: int = 0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = c; s.border_color = b
	s.set_border_width_all(w)
	s.set_corner_radius_all(r)
	return s
