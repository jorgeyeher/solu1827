class_name CalendarGenerator
extends RefCounted

static func generate_all_calendars(temporada: int, custom_seed: int = 0) -> Dictionary:
	var res = {"success": false, "creados": 0, "error": ""}
	if custom_seed != 0:
		seed(custom_seed)
		
	var ligas = DatabaseManager.fetch_rows("SELECT id FROM ligas")
	DatabaseManager.execute("BEGIN TRANSACTION;")
	
	for liga in ligas:
		var liga_id = int(liga["id"])
		if not _generar_round_robin_para_liga(liga_id, temporada):
			DatabaseManager.execute("ROLLBACK;")
			res["error"] = "Error generando calendario para liga %d" % liga_id
			return res
			
		res["creados"] += 1
		
	DatabaseManager.execute("COMMIT;")
	res["success"] = true
	return res

static func _generar_round_robin_para_liga(liga_id: int, temporada: int) -> bool:
	var existen = DatabaseManager.fetch_rows("SELECT id FROM partidos WHERE torneo_id = %d AND temporada = %d LIMIT 1" % [liga_id, temporada])
	if not existen.is_empty():
		return true # Ya existe
		
	var filas = DatabaseManager.fetch_rows("SELECT id FROM equipos WHERE liga_id = %d ORDER BY id ASC" % liga_id)
	var equipos: Array[int] = []
	for f in filas:
		equipos.append(int(f["id"]))
		
	var n = equipos.size()
	if n < 2:
		return true
		
	var _include_dummy = false
	if n % 2 != 0:
		equipos.append(-1)
		n += 1
		_include_dummy = true
		
	var num_jornadas = n - 1
	var mitad: int = n / 2
	
	for i in range(num_jornadas):
		var jornada = i + 1
		
		for j in range(mitad):
			var local = equipos[j]
			var visita = equipos[n - 1 - j]
			
			if local == -1 or visita == -1:
				continue
				
			if j % 2 == 1 or (i % 2 == 1 and j == 0):
				_guardar_partido(liga_id, temporada, jornada, visita, local)
				_guardar_partido(liga_id, temporada, jornada + num_jornadas, local, visita)
			else:
				_guardar_partido(liga_id, temporada, jornada, local, visita)
				_guardar_partido(liga_id, temporada, jornada + num_jornadas, visita, local)
				
		var ultimo = equipos.pop_back()
		equipos.insert(1, ultimo)
		
	return true

static func _guardar_partido(torneo_id: int, temporada: int, jornada: int, local: int, visita: int) -> void:
	var query = "INSERT INTO partidos (torneo_id, temporada, jornada, equipo_local_id, equipo_visita_id, jugado, goles_local, goles_visita) VALUES (%d, %d, %d, %d, %d, 0, 0, 0)" % [
		torneo_id, temporada, jornada, local, visita
	]
	DatabaseManager.execute(query)
