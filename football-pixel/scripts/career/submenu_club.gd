extends Control

const COLOR_HEADER := Color("FF5733")
const COLOR_TEXT_LIGHT := Color("FFFFFF")
const COLOR_TEXT_DARK := Color("333333")
const COLOR_PANEL_CLASIFICACIONES := Color("555555")
const COLOR_PANEL_FINANZAS := Color("7ED957")
const COLOR_PANEL_INSTALACIONES := Color("7ED9EF")
const COLOR_PANEL_HISTORIAL := Color("FFFFFF")

# Las rutas de navegación de tu juego
const MENU_CARRERA_SCENE := "res://scenes/career/menu_plantilla.tscn"
const CLASIFICACIONES_SCENE := "res://scenes/career/clasificacion.tscn"

@onready var vbox_principal: VBoxContainer = $VBoxPrincipal
@onready var header: PanelContainer = $VBoxPrincipal/Header
@onready var hbox_header: HBoxContainer = $VBoxPrincipal/Header/HBoxHeader
@onready var btn_regresar: Button = $VBoxPrincipal/Header/HBoxHeader/BtnRegresar
@onready var titulo: Label = $VBoxPrincipal/Header/HBoxHeader/Titulo

@onready var grid_opciones: GridContainer = $VBoxPrincipal/GridOpciones
@onready var panel_clasificaciones: PanelContainer = $VBoxPrincipal/GridOpciones/PanelClasificaciones
@onready var btn_clasificaciones: Button = $VBoxPrincipal/GridOpciones/PanelClasificaciones/BtnClasificaciones
@onready var panel_finanzas: PanelContainer = $VBoxPrincipal/GridOpciones/PanelFinanzas
@onready var btn_finanzas: Button = $VBoxPrincipal/GridOpciones/PanelFinanzas/BtnFinanzas
@onready var panel_instalaciones: PanelContainer = $VBoxPrincipal/GridOpciones/PanelInstalaciones
@onready var btn_instalaciones: Button = $VBoxPrincipal/GridOpciones/PanelInstalaciones/BtnInstalaciones
@onready var panel_historial: PanelContainer = $VBoxPrincipal/GridOpciones/PanelHistorial
@onready var btn_historial: Button = $VBoxPrincipal/GridOpciones/PanelHistorial/BtnHistorial

func _ready() -> void:
	configurar_estilos()
	# Conectamos las señales de los botones a sus funciones tácticas
	btn_regresar.pressed.connect(_volver_al_menu_carrera)
	btn_clasificaciones.pressed.connect(_abrir_clasificaciones)
	if btn_historial:
		btn_historial.pressed.connect(_abrir_historial)

func configurar_estilos() -> void:
	vbox_principal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox_principal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_principal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_principal.add_theme_constant_override("separation", 0)

	header.custom_minimum_size = Vector2(0, 60)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _make_panel_style(COLOR_HEADER))

	hbox_header.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_header.add_theme_constant_override("separation", 16)

	btn_regresar.text = "REGRESAR"
	btn_regresar.custom_minimum_size = Vector2(180, 0)
	_configurar_boton_header(btn_regresar)

	titulo.text = "CLUB"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", COLOR_TEXT_LIGHT)
	titulo.add_theme_font_size_override("font_size", 28)

	grid_opciones.columns = 2
	grid_opciones.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_opciones.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_opciones.add_theme_constant_override("h_separation", 0)
	grid_opciones.add_theme_constant_override("v_separation", 0)

	_configurar_panel_opcion(panel_clasificaciones, btn_clasificaciones, COLOR_PANEL_CLASIFICACIONES, "CLASIFICACIONES")
	_configurar_panel_opcion(panel_finanzas, btn_finanzas, COLOR_PANEL_FINANZAS, "FINANZAS")
	_configurar_panel_opcion(panel_instalaciones, btn_instalaciones, COLOR_PANEL_INSTALACIONES, "INSTALACIONES")
	_configurar_panel_opcion(panel_historial, btn_historial, COLOR_PANEL_HISTORIAL, "HISTORIAL")

func _configurar_panel_opcion(panel: PanelContainer, boton: Button, color_fondo: Color, texto: String) -> void:
	# 1. Expandimos el panel y le damos su color
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(color_fondo))

	# 2. Hacemos que el botón llene el espacio y sea invisible
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.size_flags_vertical = Control.SIZE_EXPAND_FILL
	boton.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	boton.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	boton.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# 3. EL PARCHE: Solo le ponemos texto por código a los paneles viejos.
	# Tu panel de Clasificaciones ya tiene su propio Label, así que lo ignoramos.
	if texto != "CLASIFICACIONES":
		boton.text = texto
		var color_texto = COLOR_TEXT_DARK
		
		boton.add_theme_color_override("font_color", color_texto)
		boton.add_theme_color_override("font_hover_color", color_texto)
		boton.add_theme_color_override("font_pressed_color", color_texto)
		boton.add_theme_color_override("font_focus_color", color_texto)
		boton.add_theme_font_size_override("font_size", 24)
		boton.alignment = HORIZONTAL_ALIGNMENT_CENTER
		boton.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	# Condición para que el texto de "Clasificaciones" no se pierda en el fondo gris oscuro
	var color_texto = COLOR_TEXT_DARK
	if texto == "CLASIFICACIONES":
		color_texto = COLOR_TEXT_LIGHT
		
	boton.add_theme_color_override("font_color", color_texto)
	boton.add_theme_color_override("font_hover_color", color_texto)
	boton.add_theme_color_override("font_pressed_color", color_texto)
	boton.add_theme_color_override("font_focus_color", color_texto)
	boton.add_theme_font_size_override("font_size", 24)
	boton.alignment = HORIZONTAL_ALIGNMENT_CENTER
	boton.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _configurar_boton_header(boton: Button) -> void:
	boton.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	boton.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	boton.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	boton.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	boton.add_theme_color_override("font_color", COLOR_TEXT_LIGHT)
	boton.add_theme_color_override("font_hover_color", COLOR_TEXT_LIGHT)
	boton.add_theme_color_override("font_pressed_color", COLOR_TEXT_LIGHT)
	boton.add_theme_color_override("font_focus_color", COLOR_TEXT_LIGHT)
	boton.add_theme_font_size_override("font_size", 22)
	boton.alignment = HORIZONTAL_ALIGNMENT_CENTER

func _make_panel_style(color_fondo: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color_fondo
	return style

# --- LAS FUNCIONES DE NAVEGACIÓN ---

func _volver_al_menu_carrera() -> void:
	get_tree().change_scene_to_file(MENU_CARRERA_SCENE)

func _abrir_clasificaciones() -> void:
	get_tree().change_scene_to_file(CLASIFICACIONES_SCENE)

func _ready_extra_conexiones() -> void:
	# Historial (si el botón existe)
	if btn_historial:
		btn_historial.pressed.connect(_abrir_historial)

func _abrir_historial() -> void:
	var HISTORIAL_SCENE := "res://scenes/career/historial.tscn"
	if ResourceLoader.exists(HISTORIAL_SCENE):
		get_tree().change_scene_to_file(HISTORIAL_SCENE)
