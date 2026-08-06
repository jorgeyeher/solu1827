class_name ClasificacionReparador
extends RefCounted

static func reparar_clasificacion_actual() -> Dictionary:
	var resumen = {
		"filas_creadas": 0,
		"filas_eliminadas": 0,
		"errores": []
	}
	
	DatabaseManager.execute("BEGIN;")
	
	var torneos_query = DatabaseManager.fetch_rows("SELECT DISTINCT torneo_id, temporada FROM partidos")
	if torneos_query.is_empty():
		DatabaseManager.execute("ROLLBACK;")
		resumen["errores"].append("No hay partidos en la base de datos.")
		return resumen
		
	for t in torneos_query:
		var torneo_id = int(t["torneo_id"])
		var temporada = int(t["temporada"])
		
		var prev_count = DatabaseManager.fetch_rows("SELECT COUNT(*) AS total FROM estadisticas_liga WHERE torneo_id = %d AND temporada = %d" % [torneo_id, temporada])
		if not prev_count.is_empty():
			resumen["filas_eliminadas"] += int(prev_count[0]["total"])
			
		DatabaseManager.execute("DELETE FROM estadisticas_liga WHERE torneo_id = %d AND temporada = %d" % [torneo_id, temporada])
		
		var stats: Dictionary = {}
		var partidos = DatabaseManager.fetch_rows("SELECT * FROM partidos WHERE torneo_id = %d AND temporada = %d AND jugado = 1" % [torneo_id, temporada])
		
		for p in partidos:
			var local_id = int(p["equipo_local_id"])
			var visita_id = int(p["equipo_visita_id"])
			var goles_l = int(p["goles_local"])
			var goles_v = int(p["goles_visita"])
			
			_asegurar_equipo_stats(stats, local_id)
			_asegurar_equipo_stats(stats, visita_id)
			
			stats[local_id]["pj"] += 1
			stats[visita_id]["pj"] += 1
			stats[local_id]["gf"] += goles_l
			stats[local_id]["gc"] += goles_v
			stats[visita_id]["gf"] += goles_v
			stats[visita_id]["gc"] += goles_l
			
			if goles_l > goles_v:
				stats[local_id]["v"] += 1
				stats[visita_id]["d"] += 1
				stats[local_id]["pts"] += 3
			elif goles_v > goles_l:
				stats[visita_id]["v"] += 1
				stats[local_id]["d"] += 1
				stats[visita_id]["pts"] += 3
			else:
				stats[local_id]["e"] += 1
				stats[visita_id]["e"] += 1
				stats[local_id]["pts"] += 1
				stats[visita_id]["pts"] += 1
				
		for equipo_id in stats.keys():
			var e = stats[equipo_id]
			var query = """
				INSERT INTO estadisticas_liga 
				(equipo_id, torneo_id, temporada, partidos_jugados, victorias, empates, derrotas, goles_favor, goles_contra, puntos)
				VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d)
			""" % [
				equipo_id, torneo_id, temporada,
				e["pj"], e["v"], e["e"], e["d"],
				e["gf"], e["gc"], e["pts"]
			]
			if DatabaseManager.execute(query):
				resumen["filas_creadas"] += 1
			else:
				resumen["errores"].append("Error insertando stats de equipo %d" % equipo_id)
				
	if resumen["errores"].is_empty():
		DatabaseManager.execute("COMMIT;")
	else:
		DatabaseManager.execute("ROLLBACK;")
		
	return resumen

static func _asegurar_equipo_stats(stats: Dictionary, equipo_id: int) -> void:
	if not stats.has(equipo_id):
		stats[equipo_id] = {
			"pj": 0, "v": 0, "e": 0, "d": 0,
			"gf": 0, "gc": 0, "pts": 0
		}
