extends Control

const MENU_PRINCIPAL = "res://scenes/career/menu_plantilla.tscn"

const COLOR_WHITE := Color("ffffff")
const COLOR_BLACK := Color("000000")
const COLOR_GRAY_SHADOW := Color("4a4a4a")
const COLOR_LOCAL := Color("005bb5")
const COLOR_VISITA := Color("e63946")
const COLOR_CYAN := Color("00b4d8")
const COLOR_ORANGE := Color("f77f00")
const COLOR_RED_SHADOW := Color("d62828")
const COLOR_MVP_YELLOW := Color("ffd166")
const COLOR_OUTLINE_GRAY := Color("7a7a7a")

@onready var fondo_cancha: TextureRect = $FondoCancha
@onready var margen_pantalla: MarginContainer = $MargenPantalla
@onready var hbox_principal: HBoxContainer = $MargenPantalla/HBoxPrincipal

# --- RUTAS MVP ---
@onready var panel_mvp: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelMVP
@onready var margin_mvp: MarginContainer = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP
@onready var vbox_mvp: VBoxContainer = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP
@onready var titulo_mvp: Label = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/TituloMVP
@onready var margen_avatar: MarginContainer = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/MargenAvatar
@onready var avatar: TextureRect = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/MargenAvatar/Avatar
@onready var nombre: Label = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/Nombre
@onready var margen_posicion_mvp: MarginContainer = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/MargenPosicion
@onready var panel_cian: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/MargenPosicion/PanelCian
@onready var texto_posicion: Label = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/MargenPosicion/PanelCian/TextoPosicion
@onready var margen_stats: MarginContainer = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/MargenStats
@onready var panel_stats_mvp: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/MargenStats/PanelStatsMVP
@onready var texto_stats: Label = $MargenPantalla/HBoxPrincipal/PanelMVP/MarginMVP/VBoxMVP/MargenStats/PanelStatsMVP/TextoStats

# --- RUTAS RESUMEN ---
@onready var panel_resumen: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelResumen
@onready var margin_resumen: MarginContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen
@onready var vbox_resumen: VBoxContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen
@onready var titulo: Label = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/Titulo
@onready var hbox_equipos: HBoxContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/HBoxEquipos
@onready var nombre_local: Label = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/HBoxEquipos/NombreLocal
@onready var espacio: Control = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/HBoxEquipos/Espacio
@onready var nombre_visita: Label = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/HBoxEquipos/NombreVisita
@onready var vbox_estadisticas: VBoxContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/VBoxEstadisticas

# Fila principal mapeada por Codex
@onready var fila_goles: HBoxContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/VBoxEstadisticas/FilaGoles
@onready var pnl_num_local: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/VBoxEstadisticas/FilaGoles/PnlNumLocal
@onready var pnl_num_visita: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/VBoxEstadisticas/FilaGoles/PnlNumVisita

# Posiciones
@onready var margen_posicion_resumen: MarginContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/MargenPosicion
@onready var panel_tabla: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/MargenPosicion/PanelTabla
@onready var margin_interno: MarginContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/MargenPosicion/PanelTabla/MarginInterno
@onready var vbox_tabla: VBoxContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/MargenPosicion/PanelTabla/MarginInterno/VBoxTabla
@onready var titulo_tabla: Label = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/MargenPosicion/PanelTabla/MarginInterno/VBoxTabla/TituloTabla
@onready var panel_local: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/MargenPosicion/PanelTabla/MarginInterno/VBoxTabla/PanelLocal
@onready var panel_visita: PanelContainer = $MargenPantalla/HBoxPrincipal/PanelResumen/MarginResumen/VBoxResumen/MargenPosicion/PanelTabla/MarginInterno/VBoxTabla/PanelVisita

@onready var btn_menu: Button = $MarginBoton/BtnMenu

func _ready() -> void:
	# 1. LA MAGIA VISUAL DE CODEX
	apply_layout_overrides()
	apply_base_panel_styles()
	apply_accent_panel_styles()
	apply_titles_style()
	apply_text_style()
	apply_statistics_style()
	apply_table_row_style()
	apply_button_style()
	
	# 2. LA MAGIA LÓGICA (Inyectar datos dinámicos)
	inyectar_datos_partido()
	
	# 3. CONECTAR EL BOTÓN
	btn_menu.pressed.connect(_volver_al_menu)

func _volver_al_menu() -> void:
	get_tree().change_scene_to_file(MENU_PRINCIPAL)

func inyectar_datos_partido() -> void:
	# A) Nombres de los equipos
	nombre_local.text = GameManager.ultimo_local
	nombre_visita.text = GameManager.ultimo_visita

	# B) Datos del MVP
	nombre.text = GameManager.mvp_nombre
	texto_posicion.text = GameManager.mvp_posicion
	texto_stats.text = "GOLES " + str(GameManager.mvp_goles) + "\nASISTENCIAS " + str(GameManager.mvp_asistencias) + "\nVALORACIÓN " + str(snapped(GameManager.mvp_valoracion, 0.1))

	# C) Goles (Ahora busca el nodo "Numero")
	pnl_num_local.get_node("Numero").text = str(GameManager.goles_local)
	pnl_num_visita.get_node("Numero").text = str(GameManager.goles_visita)

	# D) Conectar las otras estadísticas
	var fila_pos = vbox_estadisticas.get_node("FilaPosesion")
	fila_pos.get_node("PnlNumLocal/Numero").text = str(GameManager.posesion_local) + "%"
	fila_pos.get_node("PnlNumVisita/Numero").text = str(100 - GameManager.posesion_local) + "%"

	var fila_tir = vbox_estadisticas.get_node("FilaTiros")
	fila_tir.get_node("PnlNumLocal/Numero").text = str(GameManager.tiros_local)
	fila_tir.get_node("PnlNumVisita/Numero").text = str(GameManager.tiros_visita)

	var fila_fal = vbox_estadisticas.get_node("FilaFaltas")
	fila_fal.get_node("PnlNumLocal/Numero").text = str(GameManager.faltas_local)
	fila_fal.get_node("PnlNumVisita/Numero").text = str(GameManager.faltas_visita)

# ==========================================
# FUNCIONES DE ESTILO DE CODEX (INTACTAS)
# ==========================================

func apply_layout_overrides() -> void:
	margen_pantalla.add_theme_constant_override("margin_left", 100)
	margen_pantalla.add_theme_constant_override("margin_right", 100)
	margen_pantalla.add_theme_constant_override("margin_top", 80)
	margen_pantalla.add_theme_constant_override("margin_bottom", 80)
	hbox_principal.add_theme_constant_override("separation", 60)
	margin_mvp.add_theme_constant_override("margin_left", 40)
	margin_mvp.add_theme_constant_override("margin_right", 40)
	margin_mvp.add_theme_constant_override("margin_top", 40)
	margin_mvp.add_theme_constant_override("margin_bottom", 40)
	vbox_mvp.add_theme_constant_override("separation", 20)
	margen_posicion_mvp.add_theme_constant_override("margin_left", 70)
	margen_posicion_mvp.add_theme_constant_override("margin_right", 70)
	margin_resumen.add_theme_constant_override("margin_left", 60)
	margin_resumen.add_theme_constant_override("margin_right", 60)
	margin_resumen.add_theme_constant_override("margin_top", 60)
	margin_resumen.add_theme_constant_override("margin_bottom", 60)
	vbox_resumen.add_theme_constant_override("separation", 40)
	vbox_estadisticas.add_theme_constant_override("separation", 20)
	margen_posicion_resumen.add_theme_constant_override("margin_left", 150)
	margen_posicion_resumen.add_theme_constant_override("margin_right", 150)
	margin_interno.add_theme_constant_override("margin_left", 20)
	margin_interno.add_theme_constant_override("margin_right", 20)
	margin_interno.add_theme_constant_override("margin_top", 20)
	margin_interno.add_theme_constant_override("margin_bottom", 20)
	vbox_tabla.add_theme_constant_override("separation", 15)
	fondo_cancha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo_cancha.stretch_mode = TextureRect.STRETCH_SCALE

func apply_base_panel_styles() -> void:
	var retro_panel := make_stylebox(COLOR_WHITE, Color.TRANSPARENT, 0, COLOR_GRAY_SHADOW, Vector2(12, 12), 0)
	panel_mvp.add_theme_stylebox_override("panel", retro_panel)
	panel_resumen.add_theme_stylebox_override("panel", retro_panel.duplicate())

func apply_accent_panel_styles() -> void:
	panel_cian.add_theme_stylebox_override("panel", make_stylebox(COLOR_CYAN, Color.TRANSPARENT, 0, Color.TRANSPARENT, Vector2.ZERO, 0))
	var framed_panel := make_stylebox(COLOR_WHITE, COLOR_ORANGE, 4, COLOR_RED_SHADOW, Vector2(8, 8), 0)
	panel_stats_mvp.add_theme_stylebox_override("panel", framed_panel)
	panel_tabla.add_theme_stylebox_override("panel", framed_panel.duplicate())

func apply_titles_style() -> void:
	style_title_label(titulo_mvp, COLOR_MVP_YELLOW, 56, true)
	style_title_label(titulo, COLOR_BLACK, 58, false)
	style_title_label(titulo_tabla, COLOR_BLACK, 30, false)

func apply_text_style() -> void:
	nombre.add_theme_color_override("font_color", COLOR_BLACK)
	nombre.add_theme_font_size_override("font_size", 34)
	texto_posicion.add_theme_color_override("font_color", COLOR_BLACK)
	texto_posicion.add_theme_font_size_override("font_size", 26)
	texto_stats.add_theme_color_override("font_color", COLOR_BLACK)
	texto_stats.add_theme_font_size_override("font_size", 24)
	texto_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre_local.add_theme_color_override("font_color", COLOR_BLACK)
	nombre_local.add_theme_font_size_override("font_size", 40)
	nombre_visita.add_theme_color_override("font_color", COLOR_BLACK)
	nombre_visita.add_theme_font_size_override("font_size", 40)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func apply_statistics_style() -> void:
	for row in vbox_estadisticas.get_children():
		if row is HBoxContainer:
			var local_panel := row.get_node_or_null("PnlNumLocal") as PanelContainer
			var visit_panel := row.get_node_or_null("PnlNumVisita") as PanelContainer
			var center_label := row.get_node_or_null("Etiqueta") as Label
			if local_panel:
				local_panel.add_theme_stylebox_override("panel", make_stylebox(COLOR_LOCAL, Color.TRANSPARENT, 0, Color.TRANSPARENT, Vector2.ZERO, 0, 18))
				style_panel_value_label(local_panel)
			if visit_panel:
				visit_panel.add_theme_stylebox_override("panel", make_stylebox(COLOR_VISITA, Color.TRANSPARENT, 0, Color.TRANSPARENT, Vector2.ZERO, 0, 18))
				style_panel_value_label(visit_panel)
			if center_label:
				center_label.add_theme_color_override("font_color", COLOR_BLACK)
				center_label.add_theme_font_size_override("font_size", 28)
				center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func apply_table_row_style() -> void:
	var row_style := make_stylebox(COLOR_WHITE, COLOR_BLACK, 3, Color.TRANSPARENT, Vector2.ZERO, 0, 0)
	panel_local.add_theme_stylebox_override("panel", row_style)
	panel_visita.add_theme_stylebox_override("panel", row_style.duplicate())

func apply_button_style() -> void:
	var button_style := make_stylebox(COLOR_WHITE, COLOR_BLACK, 4, COLOR_BLACK, Vector2(8, 8), 0)
	for state in ["normal", "hover", "pressed", "focus"]:
		btn_menu.add_theme_stylebox_override(state, button_style.duplicate())
	btn_menu.add_theme_color_override("font_color", COLOR_BLACK)
	btn_menu.add_theme_color_override("font_hover_color", COLOR_BLACK)
	btn_menu.add_theme_color_override("font_pressed_color", COLOR_BLACK)
	btn_menu.add_theme_font_size_override("font_size", 28)

func style_title_label(label: Label, font_color: Color, font_size: int, use_outline: bool) -> void:
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", COLOR_BLACK)
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if use_outline:
		label.add_theme_color_override("font_outline_color", COLOR_OUTLINE_GRAY)
		label.add_theme_constant_override("outline_size", 4)

func style_panel_value_label(panel: PanelContainer) -> void:
	for child in panel.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", COLOR_WHITE)
			child.add_theme_font_size_override("font_size", 30)
			child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func make_stylebox(bg_color: Color, border_color: Color, border_width: int, shadow_color: Color, shadow_offset: Vector2, shadow_size: int, corner_radius: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = shadow_color
	style.shadow_offset = shadow_offset
	style.shadow_size = shadow_size
	return style
