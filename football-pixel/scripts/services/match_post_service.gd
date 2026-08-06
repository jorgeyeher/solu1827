class_name MatchPostService
extends RefCounted

## Ejecuta TODO lo que ocurre al finalizar un partido dentro de una única transacción.
## Si cualquier paso falla se hace ROLLBACK completo.
static func post_match(
	partido_id:       int,
	goles_local:      int,
	goles_visita:     int,
	equipo_local_id:  int,
	equipo_visita_id: int,
	torneo_id:        int,
	temporada:        int,
	jornada:          int,
	titulares_local:  Array,
	titulares_visita: Array,
	anotadores:       Array,   # Array[int] de IDs
	asistentes:       Array,   # Array[int] de IDs
	equipo_jugador_id: int     # 0 si es partido de IA puro
) -> Dictionary:

	# --- Guardia de idempotencia ---
	var check = DatabaseManager.fetch_rows(
		"SELECT jugado FROM partidos WHERE id = %d" % partido_id)
	if not check.is_empty() and int(check[0].get("jugado", 0)) == 1:
		return {"success": false, "error": "El partido %d ya fue procesado." % partido_id}

	DatabaseManager.execute("BEGIN;")
	var s := true

	# 1. Marcar partido como jugado
	s = s and DatabaseManager.execute(
		"UPDATE partidos SET jugado = 1, goles_local = %d, goles_visita = %d WHERE id = %d"
		% [goles_local, goles_visita, partido_id])

	# 2. Calcular resultado
	var res_local  := "empate"
	var res_visita := "empate"
	var pts_l := 1; var pts_v := 1
	var vic_l := 0; var emp_l := 1; var der_l := 0
	var vic_v := 0; var emp_v := 1; var der_v := 0

	if goles_local > goles_visita:
		res_local = "victoria"; res_visita = "derrota"
		pts_l = 3; pts_v = 0
		vic_l = 1; emp_l = 0; der_v = 1; emp_v = 0
	elif goles_visita > goles_local:
		res_local = "derrota"; res_visita = "victoria"
		pts_l = 0; pts_v = 3
		vic_v = 1; emp_v = 0; der_l = 1; emp_l = 0

	# 3. Clasificación
	s = s and DatabaseManager.execute(
		"INSERT OR IGNORE INTO estadisticas_liga (equipo_id, torneo_id, temporada) VALUES (%d, %d, %d)"
		% [equipo_local_id, torneo_id, temporada])
	s = s and DatabaseManager.execute(
		"INSERT OR IGNORE INTO estadisticas_liga (equipo_id, torneo_id, temporada) VALUES (%d, %d, %d)"
		% [equipo_visita_id, torneo_id, temporada])

	s = s and DatabaseManager.execute("""
		UPDATE estadisticas_liga SET
			partidos_jugados = partidos_jugados + 1,
			victorias = victorias + %d, empates = empates + %d, derrotas = derrotas + %d,
			goles_favor = goles_favor + %d, goles_contra = goles_contra + %d,
			puntos = puntos + %d
		WHERE equipo_id = %d AND torneo_id = %d AND temporada = %d
	""" % [vic_l, emp_l, der_l, goles_local, goles_visita, pts_l,
		   equipo_local_id, torneo_id, temporada])

	s = s and DatabaseManager.execute("""
		UPDATE estadisticas_liga SET
			partidos_jugados = partidos_jugados + 1,
			victorias = victorias + %d, empates = empates + %d, derrotas = derrotas + %d,
			goles_favor = goles_favor + %d, goles_contra = goles_contra + %d,
			puntos = puntos + %d
		WHERE equipo_id = %d AND torneo_id = %d AND temporada = %d
	""" % [vic_v, emp_v, der_v, goles_visita, goles_local, pts_v,
		   equipo_visita_id, torneo_id, temporada])

	# 4. Estadísticas de jugadores (carrera total + por temporada)
	var todos_jugadores = titulares_local + titulares_visita
	for jugador in todos_jugadores:
		var id_jug = int(jugador["id"])
		var eq_jug = int(jugador.get("equipo_id", equipo_local_id))

		# Carrera total
		s = s and DatabaseManager.execute(
			"UPDATE jugadores SET partidos_jugados = partidos_jugados + 1 WHERE id = %d" % id_jug)

		# Por temporada
		s = s and DatabaseManager.execute("""
			INSERT OR IGNORE INTO estadisticas_jugador_temporada
				(jugador_id, equipo_id, temporada, torneo_id)
			VALUES (%d, %d, %d, %d)
		""" % [id_jug, eq_jug, temporada, torneo_id])

		s = s and DatabaseManager.execute("""
			UPDATE estadisticas_jugador_temporada SET
				partidos_jugados = partidos_jugados + 1,
				minutos_jugados  = minutos_jugados  + 90
			WHERE jugador_id = %d AND temporada = %d AND torneo_id = %d
		""" % [id_jug, temporada, torneo_id])

	# Goles y asistencias
	for id_g in anotadores:
		s = s and DatabaseManager.execute("UPDATE jugadores SET goles = goles + 1 WHERE id = %d" % id_g)
		s = s and DatabaseManager.execute(
			"UPDATE estadisticas_jugador_temporada SET goles = goles + 1 WHERE jugador_id = %d AND temporada = %d AND torneo_id = %d"
			% [id_g, temporada, torneo_id])

	for id_a in asistentes:
		s = s and DatabaseManager.execute("UPDATE jugadores SET asistencias = asistencias + 1 WHERE id = %d" % id_a)
		s = s and DatabaseManager.execute(
			"UPDATE estadisticas_jugador_temporada SET asistencias = asistencias + 1 WHERE jugador_id = %d AND temporada = %d AND torneo_id = %d"
			% [id_a, temporada, torneo_id])

	# Porterías a cero
	var pt_local  = _get_portero(titulares_local)
	var pt_visita = _get_portero(titulares_visita)
	if goles_visita == 0 and not pt_local.is_empty():
		var pid = int(pt_local["id"])
		s = s and DatabaseManager.execute("UPDATE jugadores SET porterias_cero = porterias_cero + 1 WHERE id = %d" % pid)
		s = s and DatabaseManager.execute(
			"UPDATE estadisticas_jugador_temporada SET porterias_cero = porterias_cero + 1 WHERE jugador_id = %d AND temporada = %d AND torneo_id = %d"
			% [pid, temporada, torneo_id])

	if goles_local == 0 and not pt_visita.is_empty():
		var pid = int(pt_visita["id"])
		s = s and DatabaseManager.execute("UPDATE jugadores SET porterias_cero = porterias_cero + 1 WHERE id = %d" % pid)
		s = s and DatabaseManager.execute(
			"UPDATE estadisticas_jugador_temporada SET porterias_cero = porterias_cero + 1 WHERE jugador_id = %d AND temporada = %d AND torneo_id = %d"
			% [pid, temporada, torneo_id])

	# 5. Energía y moral
	for jugador in titulares_local:
		s = s and EnergyMoralService.apply_match_effects(int(jugador["id"]), 90, res_local, true)
	for jugador in titulares_visita:
		s = s and EnergyMoralService.apply_match_effects(int(jugador["id"]), 90, res_visita, true)

	# 6. Finanzas (solo para el equipo del jugador humano)
	if equipo_jugador_id > 0:
		var es_local_jugador := (equipo_local_id == equipo_jugador_id)
		var res_jugador       := res_local if es_local_jugador else res_visita
		s = s and FinanceService.registrar_resultado_partido(
			equipo_jugador_id, temporada, jornada,
			partido_id, es_local_jugador, res_jugador)

	# --- Commit o Rollback ---
	if s:
		DatabaseManager.execute("COMMIT;")
		return {"success": true, "error": "", "resultado_local": res_local, "resultado_visita": res_visita}
	else:
		DatabaseManager.execute("ROLLBACK;")
		return {"success": false, "error": "Error al guardar el acta del partido %d. ROLLBACK ejecutado." % partido_id}

# ----------------------------------------------------------------
static func _get_portero(equipo: Array) -> Dictionary:
	for j in equipo:
		var pos := str(j.get("posicion_principal", ""))
		var rol := str(j.get("rol_tactico", ""))
		if pos == "POR" or pos == "PT" or rol == "PT":
			return j
	return equipo[0] if equipo.size() > 0 else {}
