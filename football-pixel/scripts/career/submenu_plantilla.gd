extends Control

class SquadCard extends Button:
	var host_ref
	var jugador: Dictionary = {}
	var source_kind: String = ""
	var source_slot: String = ""

	func setup(p_host, p_jugador: Dictionary, p_source_kind: String, p_source_slot: String = "") -> void:
		host_ref = p_host
		jugador = p_jugador
		source_kind = p_source_kind
		source_slot = p_source_slot
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_DRAG

	func _get_drag_data(_at_position: Vector2):
		if jugador.is_empty() or host_ref == null:
			return null

		var preview = host_ref.crear_preview_arrastre(jugador, source_slot)
		set_drag_preview(preview)
		host_ref.mostrar_detalle(jugador)
		return {
			"player_id": int(jugador.get("id", -1)),
			"source_kind": source_kind,
			"source_slot": source_slot
		}

	func _can_drop_data(_at_position: Vector2, data) -> bool:
		if source_slot == "" or host_ref == null:
			return false
		return host_ref.puede_soltar_en_slot(source_slot, data)

	func _drop_data(_at_position: Vector2, data) -> void:
		if source_slot == "" or host_ref == null:
			return
		host_ref.soltar_en_slot(source_slot, data)

class FormationSlot extends PanelContainer:
	var host_ref
	var slot_name: String = ""

	func setup(p_host, p_slot_name: String) -> void:
		host_ref = p_host
		slot_name = p_slot_name

	func _can_drop_data(_at_position: Vector2, data) -> bool:
		if host_ref == null:
			return false
		return host_ref.puede_soltar_en_slot(slot_name, data)

	func _drop_data(_at_position: Vector2, data) -> void:
		if host_ref == null:
			return
		host_ref.soltar_en_slot(slot_name, data)

const FORMACIONES := {
	"4-3-3": [
		{"slot": "DC", "point": Vector2(0.50, 0.15), "matches": ["DC"]},
		{"slot": "EXI", "point": Vector2(0.18, 0.24), "matches": ["EI", "EXI"]},
		{"slot": "EXD", "point": Vector2(0.82, 0.24), "matches": ["ED", "EXD"]},
		{"slot": "MC_1", "point": Vector2(0.32, 0.46), "matches": ["MC", "MCO"]},
		{"slot": "MC_2", "point": Vector2(0.68, 0.46), "matches": ["MC", "MCO"]},
		{"slot": "MCD", "point": Vector2(0.50, 0.61), "matches": ["MCD"]},
		{"slot": "LI", "point": Vector2(0.16, 0.80), "matches": ["LI"]},
		{"slot": "DFC_1", "point": Vector2(0.39, 0.88), "matches": ["DFC"]},
		{"slot": "DFC_2", "point": Vector2(0.61, 0.88), "matches": ["DFC"]},
		{"slot": "LD", "point": Vector2(0.84, 0.80), "matches": ["LD"]},
		{"slot": "PT", "point": Vector2(0.50, 0.96), "matches": ["PT", "POR"]}
	]
}

const ROLE_COLORS := {
	"PT": Color("4f72ff"),
	"DEF": Color("ff4d4d"),
	"MID": Color("b8ef62"),
	"ATK": Color("30b9ff")
}

const ROLE_DARK := {
	"PT": Color("3047a8"),
	"DEF": Color("b62929"),
	"MID": Color("6ea527"),
	"ATK": Color("137dac")
}

@onready var label_titulo = $MarginContainer/ScrollContainer/Root/Header/Titulo
@onready var selector_formacion = $MarginContainer/ScrollContainer/Root/Header/SelectorFormacion
@onready var btn_guardar = $MarginContainer/ScrollContainer/Root/Header/BtnGuardar
@onready var btn_volver = $MarginContainer/ScrollContainer/Root/Header/BtnVolver
@onready var header = $MarginContainer/ScrollContainer/Root/Header
@onready var campo_panel = $MarginContainer/ScrollContainer/Root/CampoPanel
@onready var campo = $MarginContainer/ScrollContainer/Root/CampoPanel/Campo
@onready var banca_panel = $MarginContainer/ScrollContainer/Root/BancaPanel
@onready var banca_grid = $MarginContainer/ScrollContainer/Root/BancaPanel/BancaLayout/BancaBox/BancaGrid
@onready var ficha_panel = $MarginContainer/ScrollContainer/Root/BancaPanel/BancaLayout/FichaPanel
@onready var ficha_titulo = $MarginContainer/ScrollContainer/Root/BancaPanel/BancaLayout/FichaPanel/FichaBox/FichaTitulo
@onready var detalle_nombre = $MarginContainer/ScrollContainer/Root/BancaPanel/BancaLayout/FichaPanel/FichaBox/NombreJugador
@onready var detalle_subtitulo = $MarginContainer/ScrollContainer/Root/BancaPanel/BancaLayout/FichaPanel/FichaBox/Subtitulo
@onready var detalle_stats = $MarginContainer/ScrollContainer/Root/BancaPanel/BancaLayout/FichaPanel/FichaBox/Stats
@onready var label_estado = $MarginContainer/ScrollContainer/Root/Estado

var jugador_seleccionado: Dictionary = {}
var plantilla_jugadores: Array = []
var once_actual: Dictionary = {}
var banca_actual: Array = []
var formacion_actual: String = "4-3-3"

func _ready() -> void:
	configurar_estilos()
	btn_guardar.pressed.connect(guardar_partida)
	btn_volver.pressed.connect(volver_al_menu_partida)
	selector_formacion.item_selected.connect(_al_cambiar_formacion)
	GameManager.save_game("res://scenes/career/menu_plantilla.tscn")
	cargar_formaciones()
	cargar_plantilla()

func configurar_estilos() -> void:
	header.add_theme_constant_override("separation", 12)
	campo_panel.add_theme_stylebox_override("panel", make_style(Color("f8f8f5"), 12, Color("ccd7c7"), 2))
	banca_panel.add_theme_stylebox_override("panel", make_style(Color("f8f8f5"), 12, Color("ccd7c7"), 2))
	ficha_panel.add_theme_stylebox_override("panel", make_style(Color("fdfdfb"), 12, Color("d5dfd0"), 2))

	apply_button_theme(btn_volver, Color("e6efe3"), Color("eef6eb"), Color("d9e4d4"), Color("183018"), Color("91a78a"))
	apply_button_theme(btn_guardar, Color("e6efe3"), Color("eef6eb"), Color("d9e4d4"), Color("183018"), Color("91a78a"))
	apply_option_theme(selector_formacion, Color.WHITE, Color("183018"), Color("91a78a"))
	label_titulo.add_theme_color_override("font_color", Color("162414"))
	ficha_titulo.add_theme_color_override("font_color", Color("62755e"))
	detalle_nombre.add_theme_color_override("font_color", Color("162414"))
	detalle_subtitulo.add_theme_color_override("font_color", Color("41503d"))
	detalle_stats.add_theme_color_override("font_color", Color("243122"))
	detalle_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label_estado.add_theme_color_override("font_color", Color("243122"))

func cargar_formaciones() -> void:
	selector_formacion.clear()
	for nombre in FORMACIONES.keys():
		selector_formacion.add_item(nombre)
	selector_formacion.select(0)
	formacion_actual = selector_formacion.get_item_text(0)

func cargar_plantilla() -> void:
	var equipo_id = GameManager.equipo_jugador_id
	if equipo_id <= 0:
		label_estado.text = "No hay un equipo activo para mostrar la plantilla."
		return

	label_titulo.text = "PLANTILLA | %s" % GameManager.nombre_equipo
	plantilla_jugadores = DatabaseManager.fetch_rows("SELECT * FROM jugadores WHERE equipo_id = %d" % equipo_id)
	if plantilla_jugadores.is_empty():
		label_estado.text = "Este club no tiene jugadores cargados."
		limpiar_campo()
		limpiar_banca()
		mostrar_detalle({})
		return

	reconstruir_formacion()

func reconstruir_formacion() -> void:
	once_actual = seleccionar_once(plantilla_jugadores, formacion_actual)
	actualizar_banca_desde_once()
	actualizar_flags_titular()
	renderizar_estado_actual()

func actualizar_banca_desde_once() -> void:
	var titulares_ids: Dictionary = {}
	for slot in once_actual.keys():
		var jugador = once_actual.get(slot, {})
		if not jugador.is_empty():
			titulares_ids[int(jugador.get("id", -1))] = true
	banca_actual = seleccionar_banca(plantilla_jugadores, titulares_ids)

func renderizar_estado_actual() -> void:
	limpiar_campo()
	limpiar_banca()

	for item in obtener_slots_formacion():
		var slot_name = str(item.get("slot", ""))
		var slot_control = crear_slot_campo(slot_name, item.get("point", Vector2(0.5, 0.5)))
		var jugador = once_actual.get(slot_name, {})
		if jugador.is_empty():
			slot_control.add_child(crear_marca_slot(slot_name))
		else:
			slot_control.add_child(crear_ficha_campo(jugador, slot_name))
		campo.add_child(slot_control)

	for jugador in banca_actual:
		banca_grid.add_child(crear_ficha_banca(jugador))

	label_estado.text = "Titulares: %d | Banca: %d | Arrastra suplentes al campo." % [
		contar_titulares(),
		banca_actual.size()
	]
	actualizar_detalle_visible()

func seleccionar_once(jugadores: Array, nombre_formacion: String) -> Dictionary:
	var disponibles = jugadores.duplicate(true)
	disponibles.sort_custom(func(a, b): return obtener_media(a) > obtener_media(b))

	var once := {}
	for item in FORMACIONES.get(nombre_formacion, []):
		var slot = str(item.get("slot", ""))
		var jugador = extraer_mejor_para_posiciones(disponibles, item.get("matches", []))
		if jugador.is_empty() and not disponibles.is_empty():
			jugador = disponibles.pop_front()
		if not jugador.is_empty():
			once[slot] = jugador

	return once

func extraer_mejor_para_posiciones(disponibles: Array, posiciones: Array) -> Dictionary:
	for i in range(disponibles.size()):
		var posicion = str(disponibles[i].get("posicion_principal", ""))
		if posiciones.has(posicion):
			var jugador = disponibles[i]
			disponibles.remove_at(i)
			return jugador
	return {}

func seleccionar_banca(jugadores: Array, titulares_ids: Dictionary) -> Array:
	var restantes: Array = []
	for jugador in jugadores:
		if titulares_ids.has(int(jugador.get("id", -1))):
			continue
		restantes.append(jugador)

	restantes.sort_custom(func(a, b): return obtener_media(a) > obtener_media(b))
	return restantes

func crear_slot_campo(slot: String, posicion_normalizada: Vector2) -> FormationSlot:
	var contenedor = FormationSlot.new()
	contenedor.setup(self, slot)
	contenedor.custom_minimum_size = Vector2(96, 86)
	contenedor.anchor_left = posicion_normalizada.x
	contenedor.anchor_right = posicion_normalizada.x
	contenedor.anchor_top = posicion_normalizada.y
	contenedor.anchor_bottom = posicion_normalizada.y
	contenedor.offset_left = -48
	contenedor.offset_right = 48
	contenedor.offset_top = -43
	contenedor.offset_bottom = 43
	contenedor.add_theme_stylebox_override(
		"panel",
		make_style(Color(1, 1, 1, 0.14), 14, Color("d7ead0"), 2)
	)
	return contenedor

func crear_marca_slot(slot: String) -> Control:
	var label = Label.new()
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.text = slot.replace("_1", "").replace("_2", "")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("dcead8"))
	return label

func crear_ficha_campo(jugador: Dictionary, slot: String) -> Control:
	var contenedor = SquadCard.new()
	contenedor.setup(self, jugador, "campo", slot)
	contenedor.anchor_right = 1.0
	contenedor.anchor_bottom = 1.0
	contenedor.offset_left = 3
	contenedor.offset_top = 3
	contenedor.offset_right = -3
	contenedor.offset_bottom = -3
	contenedor.pressed.connect(func(): mostrar_detalle(jugador))

	var rol = obtener_rol_por_slot(slot)
	contenedor.add_theme_stylebox_override("normal", make_style(Color.WHITE, 12, ROLE_DARK[rol], 2))
	contenedor.add_theme_stylebox_override("hover", make_style(Color("fbfbfb"), 12, ROLE_DARK[rol], 3))
	contenedor.add_theme_stylebox_override("pressed", make_style(Color("f0f0f0"), 12, ROLE_DARK[rol], 2))
	contenedor.add_theme_color_override("font_color", Color("172015"))
	contenedor.add_theme_color_override("font_hover_color", Color("172015"))
	contenedor.add_theme_color_override("font_pressed_color", Color("172015"))

	var cuerpo = MarginContainer.new()
	cuerpo.anchor_right = 1.0
	cuerpo.anchor_bottom = 1.0
	cuerpo.add_theme_constant_override("margin_left", 6)
	cuerpo.add_theme_constant_override("margin_top", 5)
	cuerpo.add_theme_constant_override("margin_right", 6)
	cuerpo.add_theme_constant_override("margin_bottom", 6)
	contenedor.add_child(cuerpo)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	cuerpo.add_child(vbox)

	var nombre = Label.new()
	nombre.text = abreviar_nombre(str(jugador.get("nombre", "Jugador")))
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.add_theme_font_size_override("font_size", 9)
	nombre.add_theme_color_override("font_color", Color("172015"))
	vbox.add_child(nombre)

	var icon_wrap = CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(0, 28)
	vbox.add_child(icon_wrap)

	var icono = crear_icono_jugador(Vector2(38, 28))
	icon_wrap.add_child(icono)

	var barra = ColorRect.new()
	barra.color = ROLE_COLORS[rol]
	barra.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(barra)

	var texto = Label.new()
	texto.text = "%s   %d" % [str(jugador.get("posicion_principal", slot)), obtener_media(jugador)]
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 9)
	texto.add_theme_color_override("font_color", Color("07131d"))
	barra.add_child(texto)
	texto.anchor_right = 1.0
	texto.anchor_bottom = 1.0

	return contenedor

func crear_ficha_banca(jugador: Dictionary) -> Control:
	var panel = SquadCard.new()
	panel.setup(self, jugador, "banca")
	panel.custom_minimum_size = Vector2(88, 112)
	var color = obtener_color_por_posicion(str(jugador.get("posicion_principal", "")))
	panel.add_theme_stylebox_override("normal", make_style(Color.WHITE, 12, color, 3))
	panel.add_theme_stylebox_override("hover", make_style(Color("fcfcfc"), 12, color.lightened(0.1), 3))
	panel.add_theme_stylebox_override("pressed", make_style(Color("f0f0f0"), 12, color.darkened(0.1), 3))
	panel.add_theme_color_override("font_color", Color("172015"))
	panel.add_theme_color_override("font_hover_color", Color("172015"))
	panel.add_theme_color_override("font_pressed_color", Color("172015"))
	panel.pressed.connect(func(): mostrar_detalle(jugador))

	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var nombre = Label.new()
	nombre.text = abreviar_nombre(str(jugador.get("nombre", "Jugador")))
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.add_theme_font_size_override("font_size", 9)
	nombre.add_theme_color_override("font_color", Color("172015"))
	vbox.add_child(nombre)

	var icono = crear_icono_jugador(Vector2(34, 26))
	vbox.add_child(icono)

	var banda = ColorRect.new()
	banda.color = color
	banda.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(banda)

	var pos = Label.new()
	pos.text = str(jugador.get("posicion_principal", "-"))
	pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos.add_theme_font_size_override("font_size", 10)
	pos.add_theme_color_override("font_color", Color("07131d"))
	banda.add_child(pos)
	pos.anchor_right = 1.0
	pos.anchor_bottom = 1.0

	var media = Label.new()
	media.text = "Media %d" % obtener_media(jugador)
	media.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	media.add_theme_font_size_override("font_size", 11)
	media.add_theme_color_override("font_color", Color("172015"))
	vbox.add_child(media)

	return panel

func crear_icono_jugador(size: Vector2) -> Control:
	var icono = Control.new()
	icono.custom_minimum_size = size

	var cabeza = ColorRect.new()
	cabeza.color = Color.BLACK
	cabeza.position = Vector2((size.x - 16.0) / 2.0, 0)
	cabeza.size = Vector2(16, 16)
	icono.add_child(cabeza)

	var hombros = ColorRect.new()
	hombros.color = Color.BLACK
	hombros.position = Vector2((size.x - 26.0) / 2.0, 14)
	hombros.size = Vector2(26, 12)
	icono.add_child(hombros)

	return icono

func crear_preview_arrastre(jugador: Dictionary, slot_origen: String) -> Control:
	var preview = PanelContainer.new()
	preview.custom_minimum_size = Vector2(90, 62)
	var rol = obtener_rol_por_slot(slot_origen if slot_origen != "" else str(jugador.get("posicion_principal", "DC")))
	preview.add_theme_stylebox_override("panel", make_style(Color.WHITE, 10, ROLE_DARK[rol], 2))

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.add_theme_constant_override("separation", 2)
	preview.add_child(box)

	var nombre = Label.new()
	nombre.text = abreviar_nombre(str(jugador.get("nombre", "Jugador")))
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.add_theme_font_size_override("font_size", 9)
	nombre.add_theme_color_override("font_color", Color("172015"))
	box.add_child(nombre)

	var pos = Label.new()
	pos.text = "%s | %d" % [str(jugador.get("posicion_principal", "-")), obtener_media(jugador)]
	pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos.add_theme_font_size_override("font_size", 10)
	pos.add_theme_color_override("font_color", Color("172015"))
	box.add_child(pos)

	return preview

func puede_soltar_en_slot(slot_destino: String, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("player_id"):
		return false
	if slot_destino == "":
		return false

	var jugador = buscar_jugador_por_id(plantilla_jugadores, int(data.get("player_id", -1)))
	return not jugador.is_empty()

func soltar_en_slot(slot_destino: String, data) -> void:
	if not puede_soltar_en_slot(slot_destino, data):
		return

	var player_id = int(data.get("player_id", -1))
	var jugador_arrastrado = buscar_jugador_por_id(plantilla_jugadores, player_id)
	if jugador_arrastrado.is_empty():
		return

	var source_kind = str(data.get("source_kind", ""))
	var source_slot = str(data.get("source_slot", ""))
	var jugador_destino = once_actual.get(slot_destino, {})

	if source_kind == "campo":
		if source_slot == "" or source_slot == slot_destino:
			return

		once_actual[slot_destino] = jugador_arrastrado
		if jugador_destino.is_empty():
			once_actual.erase(source_slot)
		else:
			once_actual[source_slot] = jugador_destino
	elif source_kind == "banca":
		var indice_banca = indice_jugador_en_array(banca_actual, player_id)
		if indice_banca == -1:
			return

		once_actual[slot_destino] = jugador_arrastrado
		banca_actual.remove_at(indice_banca)
		if not jugador_destino.is_empty():
			banca_actual.append(jugador_destino)
	else:
		return

	ordenar_banca_actual()
	actualizar_flags_titular()
	jugador_seleccionado = jugador_arrastrado
	renderizar_estado_actual()

func ordenar_banca_actual() -> void:
	banca_actual.sort_custom(func(a, b): return obtener_media(a) > obtener_media(b))

func actualizar_flags_titular() -> void:
	var titulares_ids: Dictionary = {}
	for slot in once_actual.keys():
		var titular = once_actual.get(slot, {})
		if titular.is_empty():
			continue
		titulares_ids[int(titular.get("id", -1))] = true

	for jugador in plantilla_jugadores:
		jugador["titular"] = 1 if titulares_ids.has(int(jugador.get("id", -1))) else 0

func actualizar_detalle_visible() -> void:
	if not jugador_seleccionado.is_empty():
		var actualizado = buscar_jugador_por_id(plantilla_jugadores, int(jugador_seleccionado.get("id", -1)))
		if not actualizado.is_empty():
			mostrar_detalle(actualizado)
			return

	if contar_titulares() > 0:
		for slot in obtener_slots_formacion():
			var jugador = once_actual.get(str(slot.get("slot", "")), {})
			if not jugador.is_empty():
				mostrar_detalle(jugador)
				return

	if not banca_actual.is_empty():
		mostrar_detalle(banca_actual[0])
		return

	mostrar_detalle({})

func mostrar_detalle(jugador: Dictionary) -> void:
	jugador_seleccionado = jugador
	if jugador.is_empty():
		detalle_nombre.text = "Sin seleccion"
		detalle_subtitulo.text = "Toca o arrastra un jugador."
		detalle_stats.text = "Selecciona un titular o un suplente para ver su informacion aqui."
		return

	var posicion = str(jugador.get("posicion_principal", "-"))
	var edad = int(jugador.get("edad", 0))
	var media = obtener_media(jugador)
	var estilo = str(jugador.get("estilo_juego", "Equilibrado"))
	var moral = int(jugador.get("moral", 0))
	var energia = int(jugador.get("energia", 0))
	var valor = int(jugador.get("valor", 0))
	var pie = str(jugador.get("pie preferido", jugador.get("pie_preferido", "Diestro")))
	if pie == "Derecho":
		pie = "Diestro"
	elif pie == "Izquierdo":
		pie = "Zurdo"
	var uso_pie_malo = int(jugador.get("uso de pie malo", jugador.get("uso_pie_malo", 0)))
	var salario = int(jugador.get("salario", 0))
	var rol_actual = obtener_slot_actual_de_jugador(int(jugador.get("id", -1)))
	var estado_actual = "Titular en %s" % rol_actual if rol_actual != "" else "Disponible en banca"

	detalle_nombre.text = str(jugador.get("nombre", "Jugador"))
	detalle_subtitulo.text = "%s | %d anos | Media %d" % [posicion, edad, media]
	detalle_stats.text = "%s\nEstilo: %s\nPie: %s\nUso de pie malo: %d\nMoral: %d\nEnergia: %d\nValor: %d\nSalario: %d" % [
		estado_actual,
		estilo,
		pie,
		uso_pie_malo,
		moral,
		energia,
		valor,
		salario
	]

func buscar_jugador_por_id(jugadores: Array, jugador_id: int) -> Dictionary:
	for jugador in jugadores:
		if int(jugador.get("id", -1)) == jugador_id:
			return jugador
	return {}

func indice_jugador_en_array(jugadores: Array, jugador_id: int) -> int:
	for i in range(jugadores.size()):
		if int(jugadores[i].get("id", -1)) == jugador_id:
			return i
	return -1

func obtener_slot_actual_de_jugador(jugador_id: int) -> String:
	for slot in once_actual.keys():
		var jugador = once_actual.get(slot, {})
		if int(jugador.get("id", -1)) == jugador_id:
			return slot
	return ""

func obtener_media(jugador: Dictionary) -> int:
	if jugador.has("media"):
		return int(jugador.get("media", 0))
	if jugador.has("calidad_actual"):
		return int(jugador.get("calidad_actual", 0))
	if jugador.has("overall"):
		return int(jugador.get("overall", 0))
	return 0

func obtener_rol_por_slot(slot: String) -> String:
	if slot == "PT" or slot == "POR":
		return "PT"
	if slot.begins_with("DF") or slot == "LI" or slot == "LD":
		return "DEF"
	if slot.begins_with("MC") or slot == "MCD":
		return "MID"
	return "ATK"

func obtener_color_por_posicion(posicion: String) -> Color:
	if posicion == "PT" or posicion == "POR":
		return ROLE_COLORS["PT"]
	if ["LI", "LD", "DFC"].has(posicion):
		return ROLE_COLORS["DEF"]
	if ["MCD", "MC", "MCO"].has(posicion):
		return ROLE_COLORS["MID"]
	return ROLE_COLORS["ATK"]

func obtener_slots_formacion() -> Array:
	return FORMACIONES.get(formacion_actual, [])

func contar_titulares() -> int:
	var total := 0
	for slot in once_actual.keys():
		if not once_actual.get(slot, {}).is_empty():
			total += 1
	return total

func limpiar_campo() -> void:
	for hijo in campo.get_children():
		if hijo.name == "FieldLines":
			continue
		hijo.queue_free()

func limpiar_banca() -> void:
	for hijo in banca_grid.get_children():
		hijo.queue_free()

func _al_cambiar_formacion(index: int) -> void:
	formacion_actual = selector_formacion.get_item_text(index)
	if not plantilla_jugadores.is_empty():
		reconstruir_formacion()

func volver_al_menu_partida() -> void:
	get_tree().change_scene_to_file("res://scenes/career/menu_plantilla.tscn")

func guardar_partida() -> void:
	var equipo_id = GameManager.equipo_jugador_id
	
	# 1. LA LIMPIEZA: Mandamos a todos a la banca virtualmente en SQLite
	DatabaseManager.db.query("UPDATE jugadores SET es_titular = 0, rol_tactico = '' WHERE equipo_id = " + str(equipo_id))
	
	# 2. EL REGISTRO: Guardamos a los 11 titulares y su posición exacta
	for slot in once_actual.keys():
		var jugador = once_actual.get(slot, {})
		if not jugador.is_empty():
			var id_jugador = int(jugador.get("id", -1))
			DatabaseManager.db.query("UPDATE jugadores SET es_titular = 1, rol_tactico = '%s' WHERE id = %d" % [slot, id_jugador])
	
	# 3. EL GUARDADO DE ESTADO (Lo que ya tenías)
	if GameManager.save_game("res://scenes/career/menu_plantilla.tscn"):
		label_estado.text = "Táctica y Alineación guardadas con éxito."
	else:
		label_estado.text = "No se pudo guardar la partida."
		
	print("Base de datos actualizada con el nuevo 11 inicial.")

func apply_button_theme(
	boton: Button,
	normal: Color,
	hover: Color,
	pressed: Color,
	font_color: Color,
	border_color: Color
) -> void:
	boton.add_theme_stylebox_override("normal", make_style(normal, 10, border_color, 2))
	boton.add_theme_stylebox_override("hover", make_style(hover, 10, border_color, 2))
	boton.add_theme_stylebox_override("pressed", make_style(pressed, 10, border_color, 2))
	boton.add_theme_color_override("font_color", font_color)
	boton.add_theme_color_override("font_hover_color", font_color)
	boton.add_theme_color_override("font_pressed_color", font_color)
	boton.add_theme_color_override("font_focus_color", font_color)

func apply_option_theme(option_button: OptionButton, bg_color: Color, font_color: Color, border_color: Color) -> void:
	option_button.add_theme_stylebox_override("normal", make_style(bg_color, 10, border_color, 2))
	option_button.add_theme_stylebox_override("hover", make_style(bg_color.lightened(0.04), 10, border_color, 2))
	option_button.add_theme_stylebox_override("pressed", make_style(bg_color.darkened(0.04), 10, border_color, 2))
	option_button.add_theme_color_override("font_color", font_color)
	option_button.add_theme_color_override("font_hover_color", font_color)
	option_button.add_theme_color_override("font_pressed_color", font_color)
	option_button.add_theme_color_override("font_focus_color", font_color)

func make_style(color: Color, radius: int = 8, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
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

func abreviar_nombre(nombre: String) -> String:
	var partes = nombre.split(" ", false)
	if partes.size() >= 2:
		return "%s %s." % [partes[0], partes[1].left(1)]
	return nombre.left(10)
