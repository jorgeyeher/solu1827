class_name DatabaseValidator
extends RefCounted

static func validate_database() -> Dictionary:
	var report = {
		"status": "VALID",
		"errors": [],
		"warnings": []
	}
	
	_validar_plantillas(report)
	_validar_fixtures(report)
	_validar_resultados_estadisticas(report)
	
	if report["errors"].size() > 0:
		report["status"] = "INVALID"
		
	return report

static func _validar_plantillas(report: Dictionary) -> void:
	var num_ligas = DatabaseManager.fetch_rows("SELECT COUNT(*) AS c FROM ligas")[0]["c"]
	if int(num_ligas) == 0:
		report["errors"].append("No existen ligas.")
		
	var equipos_sin_liga = DatabaseManager.fetch_rows("SELECT e.id FROM equipos e LEFT JOIN ligas l ON e.liga_id = l.id WHERE l.id IS NULL")
	if equipos_sin_liga.size() > 0:
		report["errors"].append("%d equipos no tienen una liga valida." % equipos_sin_liga.size())
		
	var equipos = DatabaseManager.fetch_rows("SELECT id FROM equipos")
	for eq in equipos:
		var c = DatabaseManager.fetch_rows("SELECT COUNT(*) AS c FROM jugadores WHERE equipo_id = %d" % int(eq["id"]))[0]["c"]
		if int(c) < 11:
			report["errors"].append("Equipo %d tiene %d jugadores (menos de 11)." % [int(eq["id"]), int(c)])
			
	var jugs_sin_equipo = DatabaseManager.fetch_rows("SELECT id FROM jugadores WHERE equipo_id IS NULL OR equipo_id NOT IN (SELECT id FROM equipos)")
	if jugs_sin_equipo.size() > 0:
		report["errors"].append("%d jugadores no tienen un equipo valido." % jugs_sin_equipo.size())
		
	var jugs_sin_pos = DatabaseManager.fetch_rows("SELECT id FROM jugadores WHERE posicion_principal IS NULL OR posicion_principal = ''")
	if jugs_sin_pos.size() > 0:
		report["errors"].append("%d jugadores sin posicion_principal definida." % jugs_sin_pos.size())
		
	var stats_err = DatabaseManager.fetch_rows("SELECT id FROM jugadores WHERE calidad_actual > calidad_potencial OR calidad_actual < 0 OR calidad_actual > 100")
	if stats_err.size() > 0:
		report["warnings"].append("%d jugadores con atributos incoherentes (calidad > potencial)." % stats_err.size())

static func _validar_fixtures(report: Dictionary) -> void:
	var local_visita = DatabaseManager.fetch_rows("SELECT id FROM partidos WHERE equipo_local_id = equipo_visita_id")
	if local_visita.size() > 0:
		report["errors"].append("%d partidos tienen al mismo equipo como local y visitante." % local_visita.size())
		
	var equis_inexistentes = DatabaseManager.fetch_rows("SELECT p.id FROM partidos p WHERE p.equipo_local_id NOT IN (SELECT id FROM equipos) OR p.equipo_visita_id NOT IN (SELECT id FROM equipos)")
	if equis_inexistentes.size() > 0:
		report["errors"].append("%d partidos referencian equipos que no existen." % equis_inexistentes.size())

static func _validar_resultados_estadisticas(report: Dictionary) -> void:
	# Validar clasificación vs resultados
	var torneos = DatabaseManager.fetch_rows("SELECT DISTINCT torneo_id, temporada FROM estadisticas_liga")
	for t in torneos:
		var torneo_id = int(t["torneo_id"])
		var temporada = int(t["temporada"])
		
		var stats_bd = DatabaseManager.fetch_rows("SELECT * FROM estadisticas_liga WHERE torneo_id = %d AND temporada = %d" % [torneo_id, temporada])
		
		var stats_reales = {}
		var partidos = DatabaseManager.fetch_rows("SELECT * FROM partidos WHERE torneo_id = %d AND temporada = %d AND jugado = 1" % [torneo_id, temporada])
		for p in partidos:
			var l = int(p["equipo_local_id"])
			var v = int(p["equipo_visita_id"])
			var gl = int(p["goles_local"])
			var gv = int(p["goles_visita"])
			
			if not stats_reales.has(l): stats_reales[l] = {"pj":0,"pts":0,"v":0,"e":0,"d":0}
			if not stats_reales.has(v): stats_reales[v] = {"pj":0,"pts":0,"v":0,"e":0,"d":0}
			
			stats_reales[l]["pj"] += 1
			stats_reales[v]["pj"] += 1
			if gl > gv:
				stats_reales[l]["v"] += 1
				stats_reales[v]["d"] += 1
				stats_reales[l]["pts"] += 3
			elif gv > gl:
				stats_reales[v]["v"] += 1
				stats_reales[l]["d"] += 1
				stats_reales[v]["pts"] += 3
			else:
				stats_reales[l]["e"] += 1
				stats_reales[v]["e"] += 1
				stats_reales[l]["pts"] += 1
				stats_reales[v]["pts"] += 1
				
		for f in stats_bd:
			var e_id = int(f["equipo_id"])
			if not stats_reales.has(e_id):
				if int(f["partidos_jugados"]) > 0:
					report["errors"].append("Estadistica fantasma para equipo %d (0 partidos reales jugados)." % e_id)
				continue
				
			var real = stats_reales[e_id]
			if int(f["partidos_jugados"]) != real["pj"]:
				report["errors"].append("Descuadre de PJ en equipo %d: BD=%d Real=%d." % [e_id, int(f["partidos_jugados"]), real["pj"]])
			if int(f["puntos"]) != real["pts"]:
				report["errors"].append("Descuadre de Puntos en equipo %d: BD=%d Real=%d." % [e_id, int(f["puntos"]), real["pts"]])
			if int(f["victorias"]) != real["v"] or int(f["empates"]) != real["e"] or int(f["derrotas"]) != real["d"]:
				report["errors"].append("Descuadre V/E/D en equipo %d." % e_id)
