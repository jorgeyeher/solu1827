extends Node

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := CareerConfig.SAVE_VERSION
const DEFAULT_MENU_SCENE := "res://scenes/menus/menu_principal.tscn"
const DEFAULT_GAME_SCENE := "res://scenes/career/menu_plantilla.tscn"
const PLANTILLA_SUBMENU_SCENE := "res://scenes/career/submenu_plantilla.tscn"

var equipo_jugador_id: int = 0
var manager_nombre: String = ""
var nombre_equipo: String = ""
var uniforme_club: String = ""
var current_scene_path: String = DEFAULT_MENU_SCENE
var save_id: String = ""

# --- ESTADO DE CARRERA ---
var temporada_actual: int = 1
var jornada_actual: int   = 1
var torneo_activo_id: int = 0
var ultima_actualizacion: String = ""

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
		"save_version":        SAVE_VERSION,
		"save_id":             save_id,
		"equipo_jugador_id":   equipo_jugador_id,
		"manager_nombre":      manager_nombre,
		"nombre_equipo":       nombre_equipo,
		"uniforme_club":       uniforme_club,
		"current_scene_path": current_scene_path,
		"temporada_actual":    temporada_actual,
		"jornada_actual":      jornada_actual,
		"torneo_activo_id":    torneo_activo_id,
		"ultima_actualizacion": Time.get_datetime_string_from_system()
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

	equipo_jugador_id   = int(data.get("equipo_jugador_id", 0))
	manager_nombre      = str(data.get("manager_nombre", ""))
	nombre_equipo       = str(data.get("nombre_equipo", ""))
	uniforme_club       = str(data.get("uniforme_club", ""))
	save_id             = str(data.get("save_id", ""))
	temporada_actual    = int(data.get("temporada_actual", 1))
	jornada_actual      = int(data.get("jornada_actual", 1))
	torneo_activo_id    = int(data.get("torneo_activo_id", 0))
	ultima_actualizacion = str(data.get("ultima_actualizacion", ""))
	current_scene_path  = resolver_escena_guardada(str(data.get("current_scene_path", "")))
	
	if save_id != "":
		var dest_db = "user://saves/" + save_id + "/career.sqlite"
		if FileAccess.file_exists(dest_db):
			DatabaseManager.connect_to_db(dest_db)
		else:
			push_error("No se encontro la BD del save: " + dest_db)
			
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

func create_new_save() -> String:
	var timestamp = str(Time.get_unix_time_from_system())
	save_id = "save_" + timestamp
	var save_dir = "user://saves/" + save_id
	DirAccess.make_dir_recursive_absolute(save_dir)
	var original_db = "res://datos/PRUEBA.db"
	var dest_db = save_dir + "/career.sqlite"
	
	var dir = DirAccess.open("res://")
	if dir:
		dir.copy(original_db, dest_db)
	
	DatabaseManager.connect_to_db(dest_db)
	return save_id
