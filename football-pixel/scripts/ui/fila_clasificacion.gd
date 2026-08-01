extends HBoxContainer

const COLOR_TEXT := Color("333333")
const COLOR_TEXT_STRONG := Color("111111")
const COLOR_POINTS := Color("1A365D")

@onready var posicion: Label = $Posicion
@onready var nombre_equipo: Label = $NombreEquipo
@onready var pj: Label = $PJ
@onready var v: Label = $V
@onready var e: Label = $E
@onready var d: Label = $D
@onready var gf: Label = $GF
@onready var gc: Label = $GC
@onready var dg: Label = $DG
@onready var puntos: Label = $Puntos

func _ready() -> void:
	configurar_estilos()

func configurar_estilos() -> void:
	custom_minimum_size = Vector2(0, 40)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theme_override_constants/separation = 8

	nombre_equipo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre_equipo.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	nombre_equipo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nombre_equipo.add_theme_color_override("font_color", COLOR_TEXT)
	nombre_equipo.add_theme_font_size_override("font_size", 20)

	_configurar_columna_numerica(posicion, COLOR_TEXT_STRONG)
	_configurar_columna_numerica(pj, COLOR_TEXT)
	_configurar_columna_numerica(v, COLOR_TEXT)
	_configurar_columna_numerica(e, COLOR_TEXT)
	_configurar_columna_numerica(d, COLOR_TEXT)
	_configurar_columna_numerica(gf, COLOR_TEXT)
	_configurar_columna_numerica(gc, COLOR_TEXT)
	_configurar_columna_numerica(dg, COLOR_TEXT)
	_configurar_columna_numerica(puntos, COLOR_POINTS)

func _configurar_columna_numerica(label: Label, font_color: Color) -> void:
	label.custom_minimum_size = Vector2(45, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", 20)
