extends Control

const PlayerGeneration = preload("res://scripts/core/player_generation.gd")

@onready var label_estado = $MarginContainer/VBoxContainer/Estado
@onready var btn_generar = $MarginContainer/VBoxContainer/BtnGenerar
@onready var btn_volver = $MarginContainer/VBoxContainer/BtnVolver

func _ready() -> void:
	randomize()
	DatabaseManager.ensure_player_schema()
	btn_generar.pressed.connect(generar_jugadores_para_todos)
	btn_volver.pressed.connect(volver_al_menu)
	label_estado.text = "Genera jugadores faltantes hasta completar %d por equipo." % PlayerGeneration.SQUAD_TARGET

func generar_jugadores_para_todos() -> void:
	var equipos = DatabaseManager.fetch_rows("SELECT * FROM equipos ORDER BY id")
	if equipos.is_empty():
		label_estado.text = "Error: no se encontraron equipos en la base de datos."
		return

	var total_insertados := 0
	for equipo in equipos:
		var equipo_id = int(equipo.get("id", 0))
		var nombre_equipo = str(equipo.get("nombre", "Club"))
		var reputacion = int(equipo.get("reputacion", 50))

		var conteo = DatabaseManager.fetch_rows(
			"SELECT COUNT(*) AS total FROM jugadores WHERE equipo_id = %d" % equipo_id
		)
		var total_actual := 0
		if not conteo.is_empty():
			total_actual = int(conteo[0].get("total", 0))

		var faltantes = maxi(0, PlayerGeneration.SQUAD_TARGET - total_actual)
		for indice in range(faltantes):
			var jugador_data = PlayerGeneration.build_player(
				equipo_id,
				nombre_equipo,
				reputacion,
				total_actual + indice
			)
			var res = PlayerRepository.insert_player(jugador_data)
			if res.get("success", false):
				total_insertados += 1
			else:
				print("Error insertando en generador_jugadores: ", res.get("error", ""))

	label_estado.text = "Universo creado. Se generaron %d jugadores." % total_insertados

func volver_al_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/menu_principal.tscn")
