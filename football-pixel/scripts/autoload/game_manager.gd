extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1
const DEFAULT_MENU_SCENE := "res://scenes/menus/menu_principal.tscn"
const DEFAULT_GAME_SCENE := "res://scenes/career/menu_plantilla.tscn"
const PLANTILLA_SUBMENU_SCENE := "res://scenes/career/submenu_plantilla.tscn"

var equipo_jugador_id: int = 0
var manager_nombre: String = ""
var nombre_equipo: String = ""
var uniforme_club: String = ""
var current_scene_path: String = DEFAULT_MENU_SCENE

# ==================================================================
# --- DATOS TEMPORALES DEL PARTIDO (Puente entre Simulador y Resumen)
# ==================================================================
var ultimo_local := ""
var ultimo_visita := ""
var goles_local := 0
var goles_visita := 0
var posesion_local := 50
var tiros_local := 0
var tiros_visita := 0
var faltas_local := 0
var faltas_visita := 0

# --- DATOS DEL MVP ---
var mvp_nombre := ""
var mvp_posicion := ""
var mvp_goles := 0
var mvp_asistencias := 0
var mvp_valoracion := 0.0
# ==================================================================

func save_game(scene_path: String = "") -> bool:
	if scene_path != "":
		current_scene_path = scene_path

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo abrir el archivo de guardado.")
		return false

	var payload = {
		"save_version": SAVE_VERSION,
		"equipo_jugador_id": equipo_jugador_id,
		"manager_nombre": manager_nombre,
		"nombre_equipo": nombre_equipo,
		"uniforme_club": uniforme_club,
		"current_scene_path": current_scene_path
	}

	file.store_string(JSON.stringify(payload))
	return true

func load_game() -> bool:
	if not has_save():
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("No se pudo leer el archivo de guardado.")
		return false

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("El archivo de guardado no tiene un formato valido.")
		return false

	equipo_jugador_id = int(data.get("equipo_jugador_id", 0))
	manager_nombre = str(data.get("manager_nombre", ""))
	nombre_equipo = str(data.get("nombre_equipo", ""))
	uniforme_club = str(data.get("uniforme_club", ""))
	current_scene_path = resolver_escena_guardada(str(data.get("current_scene_path", "")))
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_resume_scene() -> String:
	return resolver_escena_guardada(current_scene_path)

func resolver_escena_guardada(scene_path: String) -> String:
	if scene_path == PLANTILLA_SUBMENU_SCENE:
		return DEFAULT_GAME_SCENE
	if scene_path != "" and ResourceLoader.exists(scene_path):
		return scene_path
	if equipo_jugador_id > 0 and ResourceLoader.exists(DEFAULT_GAME_SCENE):
		return DEFAULT_GAME_SCENE
	return DEFAULT_MENU_SCENE
