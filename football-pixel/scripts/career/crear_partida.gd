extends Control

const PlayerGeneration = preload("res://scripts/core/player_generation.gd")

const COLOR_OPTIONS: Array[String] = [
	"Blanco", "Negro", "Rojo", "Azul", "Verde", "Amarillo", "Naranja", "Morado"
]

const SHIELD_PATTERNS: Array[String] = [
	"Solido", "Franja vertical", "Franja horizontal", "Diagonal", "Mitad", "Cruz"
]

@onready var input_manager = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/InputManager
@onready var selector_liga = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/FilaLiga/SelectorLiga
@onready var selector_equipo = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/FilaEquipo/SelectorEquipo
@onready var input_equipo = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/DatosClub/InputNombreEquipo
@onready var input_presidente = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/DatosClub/InputPresidente
@onready var input_estadio = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/DatosClub/InputEstadio
@onready var selector_camiseta = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/Uniformes/Grid/ColorCamiseta
@onready var selector_shorts = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/Uniformes/Grid/ColorShorts
@onready var selector_calcetas = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/Uniformes/Grid/ColorCalcetas
@onready var selector_patron_escudo = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/Escudo/Grid/PatronEscudo
@onready var selector_escudo_primario = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/Escudo/Grid/ColorEscudoPrimario
@onready var selector_escudo_secundario = $MarginContainer/Root/Content/LeftPanel/Margin/VBox/Escudo/Grid/ColorEscudoSecundario
@onready var btn_empezar = $MarginContainer/Root/Botones/BtnEmpezar
@onready var btn_volver = $MarginContainer/Root/Botones/BtnVolver
@onready var label_estado = $MarginContainer/Root/Estado
@onready var label_resumen = $MarginContainer/Root/Content/RightPanel/Margin/VBox/Resumen
@onready var preview_club = $MarginContainer/Root/Content/RightPanel/Margin/VBox/ClubPreview

var equipos_columns: Dictionary = {}
var jugadores_columns: Array = []
var liga_actual_nombre := ""

func _ready() -> void:
	randomize()
	configurar_selectores()
	configurar_estilos()
	inspeccionar_esquema()
	conectar_eventos()
	cargar_ligas()
	actualizar_preview()

func configurar_selectores() -> void:
	cargar_opciones(selector_camiseta, COLOR_OPTIONS)
	cargar_opciones(selector_shorts, COLOR_OPTIONS)
	cargar_opciones(selector_calcetas, COLOR_OPTIONS)
	cargar_opciones(selector_escudo_primario, COLOR_OPTIONS)
	cargar_opciones(selector_escudo_secundario, COLOR_OPTIONS)
	cargar_opciones(selector_patron_escudo, SHIELD_PATTERNS)

	seleccionar_texto(selector_camiseta, "Rojo")
	seleccionar_texto(selector_shorts, "Blanco")
	seleccionar_texto(selector_calcetas, "Azul")
	seleccionar_texto(selector_escudo_primario, "Azul")
	seleccionar_texto(selector_escudo_secundario, "Blanco")
	seleccionar_texto(selector_patron_escudo, "Solido")

func configurar_estilos() -> void:
	apply_button_theme(btn_empezar, Color("56b84f"), Color("68c760"), Color("41963d"), Color("10210d"), Color("3c7f2f"))
	apply_button_theme(btn_volver, Color("e6efe3"), Color("eef6eb"), Color("d9e4d4"), Color("183018"), Color("91a78a"))

	for selector in [
		selector_liga,
		selector_equipo,
		selector_camiseta,
		selector_shorts,
		selector_calcetas,
		selector_patron_escudo,
		selector_escudo_primario,
		selector_escudo_secundario
	]:
		apply_option_theme(selector, Color("fbfbf8"), Color("1a2918"), Color("9ab290"))

func inspeccionar_esquema() -> void:
	DatabaseManager.ensure_player_schema()
	var equipos_info = DatabaseManager.fetch_rows("PRAGMA table_info(equipos)")
	for columna in equipos_info:
		equipos_columns[str(columna.get("name", ""))] = true
	jugadores_columns = DatabaseManager.fetch_rows("PRAGMA table_info(jugadores)")

func conectar_eventos() -> void:
	btn_empezar.pressed.connect(empezar_carrera)
	btn_volver.pressed.connect(volver_al_menu)
	selector_liga.item_selected.connect(al_seleccionar_liga)
	selector_equipo.item_selected.connect(al_seleccionar_equipo)

	for selector in [
		selector_camiseta,
		selector_shorts,
		selector_calcetas,
		selector_patron_escudo,
		selector_escudo_primario,
		selector_escudo_secundario
	]:
		selector.item_selected.connect(actualizar_preview)

	input_manager.text_changed.connect(actualizar_resumen)
	input_equipo.text_changed.connect(actualizar_resumen)
	input_presidente.text_changed.connect(actualizar_resumen)
	input_estadio.text_changed.connect(actualizar_resumen)

func cargar_ligas() -> void:
	selector_liga.clear()
	var ligas = DatabaseManager.fetch_rows("SELECT id, nombre FROM ligas ORDER BY nombre")
	for liga in ligas:
		selector_liga.add_item(str(liga["nombre"]), int(liga["id"]))
	if selector_liga.get_item_count() > 0:
		al_seleccionar_liga(0)

func al_seleccionar_liga(index: int) -> void:
	selector_equipo.clear()
	liga_actual_nombre = selector_liga.get_item_text(index)
	var liga_id = selector_liga.get_item_id(index)
	var equipos = DatabaseManager.fetch_rows(
		"SELECT id, nombre FROM equipos WHERE liga_id = %d ORDER BY nombre" % liga_id
	)
	for equipo in equipos:
		selector_equipo.add_item(str(equipo["nombre"]), int(equipo["id"]))
	if selector_equipo.get_item_count() > 0:
		al_seleccionar_equipo(0)
	else:
		actualizar_resumen()

func al_seleccionar_equipo(index: int) -> void:
	var equipo_id = selector_equipo.get_item_id(index)
	var resultados = DatabaseManager.fetch_rows("SELECT * FROM equipos WHERE id = %d" % equipo_id)
	if resultados.is_empty():
		return

	var datos: Dictionary = resultados[0]
	input_equipo.text = str(datos.get("nombre", ""))
	input_presidente.text = str(datos.get("presidente", ""))
	input_estadio.text = str(datos.get("estadio", ""))

	var visuals = parse_visuals(str(datos.get("uniforme", "")))
	seleccionar_texto(selector_camiseta, str(visuals.get("camiseta", "Rojo")))
	seleccionar_texto(selector_shorts, str(visuals.get("shorts", "Blanco")))
	seleccionar_texto(selector_calcetas, str(visuals.get("calcetas", "Azul")))
	seleccionar_texto(selector_patron_escudo, str(visuals.get("patron_escudo", "Solido")))
	seleccionar_texto(selector_escudo_primario, str(visuals.get("escudo_primario", "Azul")))
	seleccionar_texto(selector_escudo_secundario, str(visuals.get("escudo_secundario", "Blanco")))
	actualizar_preview()

func empezar_carrera() -> void:
	if input_manager.text.strip_edges() == "" or input_equipo.text.strip_edges() == "":
		label_estado.text = "El nombre del manager y del club son obligatorios."
		return

	if jugadores_columns.is_empty():
		jugadores_columns = DatabaseManager.fetch_rows("PRAGMA table_info(jugadores)")
	if jugadores_columns.is_empty():
		label_estado.text = "No se pudo leer la tabla jugadores."
		return

	label_estado.text = "Guardando club y generando plantillas..."
	var equipo_id = selector_equipo.get_selected_id()
	if not guardar_configuracion_equipo(equipo_id):
		label_estado.text = "No se pudo guardar la configuracion del club."
		return

	var generados = generar_jugadores_faltantes_para_todos()
	GameManager.equipo_jugador_id = equipo_id
	GameManager.manager_nombre = input_manager.text.strip_edges()
	GameManager.nombre_equipo = input_equipo.text.strip_edges()
	GameManager.uniforme_club = serializar_visuals()
	GameManager.save_game("res://scenes/career/menu_plantilla.tscn")

	label_estado.text = "Plantillas listas. Jugadores generados: %d" % generados
	get_tree().change_scene_to_file("res://scenes/career/menu_plantilla.tscn")

func guardar_configuracion_equipo(equipo_id: int) -> bool:
	var updates: Array[String] = []
	updates.append("nombre = '%s'" % DatabaseManager.escape_text(input_equipo.text.strip_edges()))
	updates.append("presidente = '%s'" % DatabaseManager.escape_text(input_presidente.text.strip_edges()))
	updates.append("estadio = '%s'" % DatabaseManager.escape_text(input_estadio.text.strip_edges()))
	updates.append("uniforme = '%s'" % DatabaseManager.escape_text(serializar_visuals()))
	if equipos_columns.has("escudo"):
		updates.append("escudo = '%s'" % DatabaseManager.escape_text(serializar_escudo()))

	var query = "UPDATE equipos SET %s WHERE id = %d" % [", ".join(updates), equipo_id]
	return DatabaseManager.execute(query)

func generar_jugadores_faltantes_para_todos() -> int:
	var equipos = DatabaseManager.fetch_rows("SELECT * FROM equipos ORDER BY id")
	var total_insertados := 0
	for equipo in equipos:
		var equipo_id = int(equipo["id"])
		var nombre_equipo = str(equipo["nombre"])
		var reputacion = int(equipo.get("reputacion", 50))
		var existentes = DatabaseManager.fetch_rows(
			"SELECT COUNT(*) AS total FROM jugadores WHERE equipo_id = %d" % equipo_id
		)
		var total_actual := 0
		if not existentes.is_empty():
			total_actual = int(existentes[0].get("total", 0))

		var faltantes = maxi(0, PlayerGeneration.SQUAD_TARGET - total_actual)
		for indice in range(faltantes):
			var jugador = construir_jugador(equipo_id, nombre_equipo, reputacion, total_actual + indice)
			if insertar_jugador(jugador):
				total_insertados += 1
	return total_insertados

func construir_jugador(equipo_id: int, nombre_equipo: String, reputacion: int, orden_plantilla: int) -> Dictionary:
	return PlayerGeneration.build_player(equipo_id, nombre_equipo, reputacion, orden_plantilla)

func insertar_jugador(jugador: Dictionary) -> bool:
	var columnas: Array[String] = []
	var valores_sql: Array[String] = []
	for columna in jugadores_columns:
		var nombre_columna = str(columna.get("name", ""))
		if nombre_columna == "" or int(columna.get("pk", 0)) == 1:
			continue

		var valor = resolver_valor_columna(columna, jugador)
		if valor == null and int(columna.get("notnull", 0)) == 0:
			continue

		columnas.append(nombre_columna)
		valores_sql.append(a_sql_literal(valor))

	if columnas.is_empty():
		return false

	var columnas_sql: Array[String] = []
	for columna in columnas:
		columnas_sql.append(DatabaseManager.quote_identifier(columna))

	var query = "INSERT INTO jugadores (%s) VALUES (%s)" % [",".join(columnas_sql), ",".join(valores_sql)]
	return DatabaseManager.execute(query)

func resolver_valor_columna(columna: Dictionary, jugador: Dictionary):
	var nombre_columna = str(columna.get("name", ""))
	if jugador.has(nombre_columna):
		return jugador[nombre_columna]

	var tipo = str(columna.get("type", "")).to_upper()
	if int(columna.get("notnull", 0)) == 1:
		if "INT" in tipo:
			return 0
		if "REAL" in tipo or "FLOA" in tipo or "DOUB" in tipo:
			return 0.0
		return ""
	return null

func a_sql_literal(valor) -> String:
	if valor == null:
		return "NULL"
	if valor is String:
		return "'%s'" % DatabaseManager.escape_text(valor)
	if valor is bool:
		return "1" if valor else "0"
	return str(valor)

func cargar_opciones(selector: OptionButton, opciones: Array[String]) -> void:
	selector.clear()
	for opcion in opciones:
		selector.add_item(opcion)

func seleccionar_texto(selector: OptionButton, texto: String) -> void:
	for i in range(selector.item_count):
		if selector.get_item_text(i) == texto:
			selector.select(i)
			return
	selector.select(0)

func parse_visuals(valor: String) -> Dictionary:
	var visuals = {
		"camiseta": "Rojo",
		"shorts": "Blanco",
		"calcetas": "Azul",
		"patron_escudo": "Solido",
		"escudo_primario": "Azul",
		"escudo_secundario": "Blanco"
	}
	if not valor.contains("="):
		return visuals
	for parte in valor.split(";"):
		var segmentos = parte.split("=")
		if segmentos.size() != 2:
			continue
		var key = segmentos[0].strip_edges()
		var data = segmentos[1].strip_edges()
		if visuals.has(key):
			visuals[key] = data
	return visuals

func serializar_visuals() -> String:
	return "camiseta=%s;shorts=%s;calcetas=%s;patron_escudo=%s;escudo_primario=%s;escudo_secundario=%s" % [
		get_selected_text(selector_camiseta),
		get_selected_text(selector_shorts),
		get_selected_text(selector_calcetas),
		get_selected_text(selector_patron_escudo),
		get_selected_text(selector_escudo_primario),
		get_selected_text(selector_escudo_secundario)
	]

func serializar_escudo() -> String:
	return "patron=%s;primario=%s;secundario=%s" % [
		get_selected_text(selector_patron_escudo),
		get_selected_text(selector_escudo_primario),
		get_selected_text(selector_escudo_secundario)
	]

func get_selected_text(selector: OptionButton) -> String:
	return selector.get_item_text(selector.selected)

func actualizar_preview(_index: int = -1) -> void:
	preview_club.set_visuals({
		"camiseta": get_selected_text(selector_camiseta),
		"shorts": get_selected_text(selector_shorts),
		"calcetas": get_selected_text(selector_calcetas),
		"patron_escudo": get_selected_text(selector_patron_escudo),
		"escudo_primario": get_selected_text(selector_escudo_primario),
		"escudo_secundario": get_selected_text(selector_escudo_secundario)
	})
	actualizar_resumen()

func actualizar_resumen(_text: String = "") -> void:
	var nombre_manager = input_manager.text.strip_edges()
	if nombre_manager == "":
		nombre_manager = "Manager pendiente"

	label_resumen.text = "Liga: %s\nClub: %s\nPresidente: %s\nEstadio: %s\nManager: %s\nUniforme: %s / %s / %s\nEscudo: %s, %s y %s" % [
		liga_actual_nombre,
		input_equipo.text.strip_edges(),
		input_presidente.text.strip_edges(),
		input_estadio.text.strip_edges(),
		nombre_manager,
		get_selected_text(selector_camiseta),
		get_selected_text(selector_shorts),
		get_selected_text(selector_calcetas),
		get_selected_text(selector_patron_escudo),
		get_selected_text(selector_escudo_primario),
		get_selected_text(selector_escudo_secundario)
	]

func volver_al_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/menu_principal.tscn")

func apply_button_theme(
	boton: Button,
	normal: Color,
	hover: Color,
	pressed: Color,
	font_color: Color,
	border_color: Color
) -> void:
	boton.add_theme_stylebox_override("normal", make_style(normal, border_color))
	boton.add_theme_stylebox_override("hover", make_style(hover, border_color))
	boton.add_theme_stylebox_override("pressed", make_style(pressed, border_color))
	boton.add_theme_color_override("font_color", font_color)
	boton.add_theme_color_override("font_hover_color", font_color)
	boton.add_theme_color_override("font_pressed_color", font_color)
	boton.add_theme_color_override("font_focus_color", font_color)

func apply_option_theme(option_button: OptionButton, bg_color: Color, font_color: Color, border_color: Color) -> void:
	option_button.add_theme_stylebox_override("normal", make_style(bg_color, border_color))
	option_button.add_theme_stylebox_override("hover", make_style(bg_color.lightened(0.03), border_color))
	option_button.add_theme_stylebox_override("pressed", make_style(bg_color.darkened(0.03), border_color))
	option_button.add_theme_color_override("font_color", font_color)
	option_button.add_theme_color_override("font_hover_color", font_color)
	option_button.add_theme_color_override("font_pressed_color", font_color)
	option_button.add_theme_color_override("font_focus_color", font_color)

func make_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style
