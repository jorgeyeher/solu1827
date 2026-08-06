extends Control

@onready var label_manager = $MarginContainer/Root/Header/Manager
@onready var label_club = $MarginContainer/Root/Header/Club
@onready var btn_guardar = $MarginContainer/Root/Header/BtnGuardar
@onready var btn_menu_principal = $MarginContainer/Root/Header/BtnMenuPrincipal
@onready var label_estado = $MarginContainer/Root/Estado
@onready var label_local = $MarginContainer/Root/Partido/MatchRow/Local/Card/Nombre
@onready var label_visitante = $MarginContainer/Root/Partido/MatchRow/Visitante/Card/Nombre
@onready var card_local = $MarginContainer/Root/Partido/MatchRow/Local/Card
@onready var card_visitante = $MarginContainer/Root/Partido/MatchRow/Visitante/Card
@onready var label_estadio = $MarginContainer/Root/Partido/Info/Estadio
@onready var label_fecha = $MarginContainer/Root/Partido/Info/Fecha
@onready var btn_ir_partido = $MarginContainer/Root/Partido/BtnRow/BtnIrPartido
@onready var btn_avanzar_jornada = $MarginContainer/Root/Partido/BtnRow/BtnAvanzarJornada
@onready var btn_club = $MarginContainer/Root/Secciones/Grid/BtnClub
@onready var btn_plantilla = $MarginContainer/Root/Secciones/Grid/BtnPlantilla
@onready var btn_cantera = $MarginContainer/Root/Secciones/Grid/BtnCantera
@onready var btn_empleados = $MarginContainer/Root/Secciones/Grid/BtnEmpleados

func _ready() -> void:
	configurar_estilos()
	conectar_botones()
	GameManager.save_game("res://scenes/career/menu_plantilla.tscn")
	cargar_dashboard()

	if OS.is_debug_build():
		var btn_reset_dev = Button.new()
		btn_reset_dev.text = "Restaurar datos"
		apply_button_theme(btn_reset_dev, Color("ff4d4d"), Color("ff6666"), Color("cc0000"), Color.WHITE, Color("660000"))
		btn_reset_dev.pressed.connect(pedir_confirmacion_reset)
		$MarginContainer/Root/Header.add_child(btn_reset_dev)

func pedir_confirmacion_reset() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Confirmar Reset"
	dialog.dialog_text = "Restaurar la base de datos a su estado original para este save?"
	dialog.confirmed.connect(ejecutar_reset_datos)
	add_child(dialog)
	dialog.popup_centered()

func ejecutar_reset_datos() -> void:
	if GameManager.save_id == "":
		mostrar_error("No hay un save activo para restaurar.")
		return
	
	DatabaseManager.db.close_db()
	var dest_db = "user://saves/" + GameManager.save_id + "/career.sqlite"
	var dir = DirAccess.open("user://saves/" + GameManager.save_id)
	if dir:
		dir.remove("career.sqlite")
		
	var res_dir = DirAccess.open("res://")
	if res_dir:
		res_dir.copy("res://datos/PRUEBA.db", dest_db)
		
	DatabaseManager.connect_to_db(dest_db)
	label_estado.text = "Datos restaurados con exito."
	cargar_dashboard()

func configurar_estilos() -> void:
	apply_button_theme(btn_guardar, Color("2a3d27"), Color("3a5434"), Color("1d2c1a"), Color("c8e6c9"), Color("4a7a44"))
	apply_button_theme(btn_menu_principal, Color("1a1e25"), Color("222830"), Color("111419"), Color("90a4ae"), Color("37474f"))
	apply_button_theme(btn_ir_partido, Color("1565c0"), Color("1976d2"), Color("0d47a1"), Color("e3f2fd"), Color("0d47a1"))
	apply_button_theme(btn_avanzar_jornada, Color("e65100"), Color("f4511e"), Color("bf360c"), Color("fff3e0"), Color("bf360c"))

	label_manager.add_theme_color_override("font_color", Color("b0bec5"))
	label_manager.add_theme_font_size_override("font_size", 16)
	label_club.add_theme_color_override("font_color", Color("81c784"))
	label_club.add_theme_font_size_override("font_size", 18)
	label_estado.add_theme_color_override("font_color", Color("90a4ae"))
	label_estadio.add_theme_color_override("font_color", Color("78909c"))
	label_fecha.add_theme_color_override("font_color", Color("78909c"))

	card_local.add_theme_stylebox_override("panel", make_style(Color("162d1a"), 8, Color("2e7d32"), 2))
	card_visitante.add_theme_stylebox_override("panel", make_style(Color("162d1a"), 8, Color("2e7d32"), 2))
	label_local.add_theme_color_override("font_color", Color("a5d6a7"))
	label_local.add_theme_font_size_override("font_size", 20)
	label_visitante.add_theme_color_override("font_color", Color("a5d6a7"))
	label_visitante.add_theme_font_size_override("font_size", 20)

	apply_button_theme(btn_club, Color("1b2e1e"), Color("243d27"), Color("12201a"), Color("81c784"), Color("2e7d32"), 6)
	apply_button_theme(btn_plantilla, Color("1b2c1f"), Color("243d27"), Color("12201a"), Color("a5d6a7"), Color("388e3c"), 6)
	apply_button_theme(btn_cantera, Color("1b2c1f"), Color("243d27"), Color("12201a"), Color("a5d6a7"), Color("388e3c"), 6)
	apply_button_theme(btn_empleados, Color("1b2e1e"), Color("243d27"), Color("12201a"), Color("81c784"), Color("2e7d32"), 6)

func conectar_botones() -> void:
	btn_guardar.pressed.connect(guardar_partida)
	btn_menu_principal.pressed.connect(volver_al_menu_principal)
	btn_ir_partido.pressed.connect(ir_al_partido)
	btn_avanzar_jornada.pressed.connect(abrir_avanzar_jornada)
	btn_club.pressed.connect(abrir_club)
	btn_plantilla.pressed.connect(abrir_plantilla)
	btn_cantera.pressed.connect(func(): mostrar_modulo("CANTERA"))
	btn_empleados.pressed.connect(func(): mostrar_modulo("EMPLEADOS"))

func cargar_dashboard() -> void:
	var equipo_id = GameManager.equipo_jugador_id
	if equipo_id <= 0:
		mostrar_error("No hay un equipo de jugador seleccionado.")
		return

	label_manager.text = "Manager: %s" % GameManager.manager_nombre
	label_club.text = "Club: %s" % GameManager.nombre_equipo

	var partido = obtener_proximo_partido(equipo_id)
	if partido.is_empty():
		label_local.text = GameManager.nombre_equipo
		label_visitante.text = "Rival pendiente"
		label_estadio.text = "Estadio: calendario no generado"
		label_fecha.text = "Fecha: pendiente"
		label_estado.text = "Aun no hay un proximo partido. Genera el calendario para continuar."
		btn_ir_partido.disabled = true
		return

	btn_ir_partido.disabled = false
	label_local.text = str(partido.get("local", "LOCAL"))
	label_visitante.text = str(partido.get("visitante", "VISITANTE"))
	label_estadio.text = "Estadio: %s" % str(partido.get("estadio", "Por definir"))
	label_fecha.text = "Jornada %s | Temporada %s" % [
		str(partido.get("jornada", 1)),
		str(partido.get("temporada", 1))
	]
	label_estado.text = "Siguiente compromiso en %s." % str(partido.get("liga", "tu liga"))
	
	# Mostrar saldo financiero si la tabla existe
	var saldo_rows = DatabaseManager.fetch_rows(
		"SELECT name FROM sqlite_master WHERE type='table' AND name='movimientos_financieros'")
	if not saldo_rows.is_empty():
		var saldo = FinanceService.get_saldo_actual(GameManager.equipo_jugador_id)
		label_estado.text += "\nSaldo: $%s" % _formato_dinero(saldo)

func obtener_proximo_partido(equipo_id: int) -> Dictionary:
	var query = """
		SELECT
			p.temporada,
			p.jornada,
			l.nombre AS liga,
			el.nombre AS local,
			ev.nombre AS visitante,
			el.estadio AS estadio
		FROM partidos p
		JOIN ligas l ON l.id = p.torneo_id
		JOIN equipos el ON el.id = p.equipo_local_id
		JOIN equipos ev ON ev.id = p.equipo_visita_id
		WHERE (p.equipo_local_id = %d OR p.equipo_visita_id = %d) AND p.jugado = 0
		ORDER BY p.temporada ASC, p.jornada ASC, p.id ASC
		LIMIT 1
	""" % [equipo_id, equipo_id]

	var resultados = DatabaseManager.fetch_rows(query)
	if resultados.is_empty():
		return {}
	return resultados[0]

func ir_al_partido() -> void:
	var titulares = DatabaseManager.fetch_rows("SELECT * FROM jugadores WHERE equipo_id = %d AND es_titular = 1" % GameManager.equipo_jugador_id)
	if titulares.size() != 11:
		mostrar_error("Alineacion invalida: Debes tener 11 titulares.")
		return
		
	var has_pt = false
	for t in titulares:
		var r = str(t.get("rol_tactico", ""))
		var p = str(t.get("posicion_principal", ""))
		if r == "PT" or p == "PT" or p == "POR":
			has_pt = true
			break
			
	if not has_pt:
		mostrar_error("Alineacion invalida: Debes tener un portero (PT).")
		return

	get_tree().change_scene_to_file("res://scenes/match/simulacion_partido.tscn")

func mostrar_modulo(nombre_modulo: String) -> void:
	label_estado.text = "Modulo %s listo para construir." % nombre_modulo

func abrir_club() -> void:
	get_tree().change_scene_to_file("res://scenes/career/submenu_club.tscn")

func abrir_plantilla() -> void:
	get_tree().change_scene_to_file("res://scenes/career/submenu_plantilla.tscn")

func abrir_avanzar_jornada() -> void:
	get_tree().change_scene_to_file("res://scenes/career/avanzar_jornada.tscn")

func _formato_dinero(valor: int) -> String:
	var s := str(abs(valor))
	var resultado := ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			resultado += ","
		resultado += s[i]
	return ("-" if valor < 0 else "") + resultado

func guardar_partida() -> void:
	if GameManager.save_game("res://scenes/career/menu_plantilla.tscn"):
		label_estado.text = "Partida guardada."
	else:
		label_estado.text = "No se pudo guardar la partida."

func volver_al_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/menu_principal.tscn")

func mostrar_error(texto: String) -> void:
	label_estado.text = texto
	label_local.text = "LOCAL"
	label_visitante.text = "VISITANTE"
	label_estadio.text = "Estadio: sin datos"
	label_fecha.text = "Fecha: sin datos"

func apply_button_theme(
	boton: Button,
	normal: Color,
	hover: Color,
	pressed: Color,
	font_color: Color,
	border_color: Color,
	radius: int = 8
) -> void:
	boton.add_theme_stylebox_override("normal", make_style(normal, radius, border_color, 2))
	boton.add_theme_stylebox_override("hover", make_style(hover, radius, border_color, 2))
	boton.add_theme_stylebox_override("pressed", make_style(pressed, radius, border_color, 2))
	boton.add_theme_color_override("font_color", font_color)
	boton.add_theme_color_override("font_hover_color", font_color)
	boton.add_theme_color_override("font_pressed_color", font_color)
	boton.add_theme_color_override("font_focus_color", font_color)

func make_style(
	color: Color,
	radius: int = 8,
	border: Color = Color.TRANSPARENT,
	width: int = 0
) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.border_width_bottom = width
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
