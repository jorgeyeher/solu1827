extends Control

func _ready() -> void:
	configurar_estilos()
	$VBoxContainer/BtnSalir.pressed.connect(cerrar_juego)
	$VBoxContainer/BtnNuevaPartida.pressed.connect(empezar_partida)
	$VBoxContainer/BtnCargar.pressed.connect(cargar_partida)
	actualizar_boton_cargar()

func cerrar_juego() -> void:
	print("Cerrando Pixel Manager...")
	get_tree().quit()

func empezar_partida() -> void:
	print("Yendo a la configuracion de partida...")
	get_tree().change_scene_to_file("res://scenes/career/crear_partida.tscn")

func cargar_partida() -> void:
	if not GameManager.load_game():
		print("No se encontro una partida guardada valida.")
		actualizar_boton_cargar()
		return

	get_tree().change_scene_to_file(GameManager.get_resume_scene())

func actualizar_boton_cargar() -> void:
	var btn_cargar: Button = $VBoxContainer/BtnCargar
	btn_cargar.disabled = not GameManager.has_save()
	btn_cargar.text = "CARGAR PARTIDA" if not btn_cargar.disabled else "SIN PARTIDA GUARDADA"

func configurar_estilos() -> void:
	var btn_nueva: Button = $VBoxContainer/BtnNuevaPartida
	var btn_cargar: Button = $VBoxContainer/BtnCargar
	var btn_salir: Button = $VBoxContainer/BtnSalir

	apply_button_theme(btn_nueva, Color("56b84f"), Color("68c760"), Color("41963d"), Color("12210f"))
	apply_button_theme(btn_cargar, Color("d8f0d3"), Color("e6f7e2"), Color("c1deb8"), Color("12210f"), Color("8ca189"))
	apply_button_theme(btn_salir, Color("1d2f18"), Color("274121"), Color("12210f"), Color("f7fff5"))

func apply_button_theme(
	boton: Button,
	normal: Color,
	hover: Color,
	pressed: Color,
	font_color: Color,
	border_color: Color = Color("2f4a2b")
) -> void:
	boton.add_theme_stylebox_override("normal", make_style(normal, border_color))
	boton.add_theme_stylebox_override("hover", make_style(hover, border_color))
	boton.add_theme_stylebox_override("pressed", make_style(pressed, border_color))
	boton.add_theme_stylebox_override("disabled", make_style(normal.darkened(0.08), border_color.darkened(0.1)))
	boton.add_theme_color_override("font_color", font_color)
	boton.add_theme_color_override("font_hover_color", font_color)
	boton.add_theme_color_override("font_pressed_color", font_color)
	boton.add_theme_color_override("font_focus_color", font_color)
	boton.add_theme_color_override("font_disabled_color", font_color.darkened(0.2))

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
