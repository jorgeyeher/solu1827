class_name CareerService
extends RefCounted

# ================================================================
# CONSULTAS DE ESTADO
# ================================================================

## Devuelve la jornada más baja con partidos pendientes, o -1 si la temporada terminó.
static func get_current_jornada(torneo_id: int, temporada: int) -> int:
	var rows = DatabaseManager.fetch_rows("""
		SELECT MIN(jornada) AS jornada_min
		FROM partidos
		WHERE torneo_id = %d AND temporada = %d AND jugado = 0
	""" % [torneo_id, temporada])
	if rows.is_empty() or rows[0]["jornada_min"] == null:
		return -1
	return int(rows[0]["jornada_min"])

## Devuelve todos los partidos (jugados y pendientes) de una jornada.
static func get_partidos_jornada(torneo_id: int, temporada: int, jornada: int) -> Array:
	return DatabaseManager.fetch_rows("""
		SELECT
			p.id, p.jugado, p.goles_local, p.goles_visita,
			p.equipo_local_id, p.equipo_visita_id,
			el.nombre AS local_nombre,
			ev.nombre AS visita_nombre
		FROM partidos p
		JOIN equipos el ON el.id = p.equipo_local_id
		JOIN equipos ev ON ev.id = p.equipo_visita_id
		WHERE p.torneo_id = %d AND p.temporada = %d AND p.jornada = %d
		ORDER BY p.id ASC
	""" % [torneo_id, temporada, jornada])

## True si todos los partidos de la jornada han sido disputados.
static func jornada_completada(torneo_id: int, temporada: int, jornada: int) -> bool:
	var rows = DatabaseManager.fetch_rows("""
		SELECT COUNT(*) AS pendientes FROM partidos
		WHERE torneo_id = %d AND temporada = %d AND jornada = %d AND jugado = 0
	""" % [torneo_id, temporada, jornada])
	return rows.is_empty() or int(rows[0]["pendientes"]) == 0

# ================================================================
# SIMULACIÓN IA
# ================================================================

## Simula un partido entre dos equipos de IA y devuelve {goles_local, goles_visita}.
static func simular_partido_ia(loc_id: int, vis_id: int) -> Dictionary:
	var r_loc = DatabaseManager.fetch_rows("SELECT reputacion FROM equipos WHERE id = %d" % loc_id)
	var r_vis = DatabaseManager.fetch_rows("SELECT reputacion FROM equipos WHERE id = %d" % vis_id)

	var rep_l := float(r_loc[0].get("reputacion", 50)) * 1.1 if not r_loc.is_empty() else 55.0
	var rep_v := float(r_vis[0].get("reputacion", 50)) if not r_vis.is_empty() else 50.0

	rep_l += randf_range(0.0, 30.0)
	rep_v += randf_range(0.0, 30.0)
	var total = rep_l + rep_v
	if total <= 0.0: total = 1.0

	var goles_l := 0
	var goles_v := 0
	for _i in range(randi_range(3, 7)):
		var prob_l = rep_l / total
		if randf() < prob_l:
			if randf() < 0.33: goles_l += 1
		else:
			if randf() < 0.33: goles_v += 1

	return {"goles_local": goles_l, "goles_visita": goles_v}

# ================================================================
# AVANCE DE JORNADA
# ================================================================

## Simula todos los partidos de IA pendientes en la jornada actual.
## Devuelve {success, error, partidos_simulados, jornada, temporada_finalizada}.
static func advance_jornada(equipo_jugador_id: int, torneo_id: int, temporada: int) -> Dictionary:
	var resultado := {
		"success": false,
		"error": "",
		"partidos_simulados": [],
		"jornada": -1,
		"temporada_finalizada": false
	}

	var jornada = get_current_jornada(torneo_id, temporada)
	if jornada == -1:
		resultado["temporada_finalizada"] = true
		resultado["error"] = "No hay más jornadas pendientes en esta temporada."
		return resultado

	resultado["jornada"] = jornada

	# Verificar que el partido del jugador ya fue disputado
	var mi_partido = DatabaseManager.fetch_rows("""
		SELECT id, jugado FROM partidos
		WHERE torneo_id = %d AND temporada = %d AND jornada = %d
		  AND (equipo_local_id = %d OR equipo_visita_id = %d)
	""" % [torneo_id, temporada, jornada, equipo_jugador_id, equipo_jugador_id])

	if not mi_partido.is_empty() and int(mi_partido[0].get("jugado", 0)) == 0:
		resultado["error"] = "Debes jugar tu partido antes de avanzar la jornada."
		return resultado

	# Simular todos los partidos de IA pendientes
	var partidos_pendientes = DatabaseManager.fetch_rows("""
		SELECT p.id, p.equipo_local_id, p.equipo_visita_id,
		       el.nombre AS local_nombre, ev.nombre AS visita_nombre
		FROM partidos p
		JOIN equipos el ON el.id = p.equipo_local_id
		JOIN equipos ev ON ev.id = p.equipo_visita_id
		WHERE p.torneo_id = %d AND p.temporada = %d AND p.jornada = %d AND p.jugado = 0
	""" % [torneo_id, temporada, jornada])

	for partido in partidos_pendientes:
		var pid  := int(partido["id"])
		var l_id := int(partido["equipo_local_id"])
		var v_id := int(partido["equipo_visita_id"])
		var sim  := simular_partido_ia(l_id, v_id)
		var gl   := sim["goles_local"]
		var gv   := sim["goles_visita"]

		# Cargar titulares IA para efectos de energía/moral
		var tit_l = DatabaseManager.fetch_rows(
			"SELECT id, equipo_id FROM jugadores WHERE equipo_id = %d AND es_titular = 1" % l_id)
		var tit_v = DatabaseManager.fetch_rows(
			"SELECT id, equipo_id FROM jugadores WHERE equipo_id = %d AND es_titular = 1" % v_id)
		if tit_l.is_empty():
			tit_l = DatabaseManager.fetch_rows(
				"SELECT id, equipo_id FROM jugadores WHERE equipo_id = %d LIMIT 11" % l_id)
		if tit_v.is_empty():
			tit_v = DatabaseManager.fetch_rows(
				"SELECT id, equipo_id FROM jugadores WHERE equipo_id = %d LIMIT 11" % v_id)

		var res = MatchPostService.post_match(
			pid, gl, gv, l_id, v_id, torneo_id, temporada, jornada,
			tit_l, tit_v, [], [], 0)  # Sin finanzas de jugador en partidos IA

		if not res["success"]:
			resultado["error"] = res["error"]
			return resultado

		resultado["partidos_simulados"].append({
			"local":        str(partido["local_nombre"]),
			"visita":       str(partido["visita_nombre"]),
			"goles_local":  gl,
			"goles_visita": gv
		})

	# Guardar snapshot de clasificación para esta jornada
	StandingsService.save_jornada_snapshot(torneo_id, temporada, jornada)

	# Recuperación de energía del equipo del jugador
	var ids_jugaron: Array[int] = []
	if not mi_partido.is_empty():
		var tit_jugador = DatabaseManager.fetch_rows(
			"SELECT id FROM jugadores WHERE equipo_id = %d AND es_titular = 1" % equipo_jugador_id)
		for j in tit_jugador:
			ids_jugaron.append(int(j["id"]))
	EnergyMoralService.recover_jornada(equipo_jugador_id, ids_jugaron)

	# Finanzas del club del jugador por la jornada
	FinanceService.pagar_salarios(equipo_jugador_id, temporada, jornada)
	FinanceService.registrar_costo_operativo(equipo_jugador_id, temporada, jornada)

	# ¿La temporada terminó?
	var siguiente = get_current_jornada(torneo_id, temporada)
	if siguiente == -1:
		resultado["temporada_finalizada"] = true
		close_season(torneo_id, temporada)

	resultado["success"] = true
	return resultado

# ================================================================
# GESTIÓN DE TEMPORADA
# ================================================================

## Cierra la temporada: guarda campeón, marca como finalizada.
static func close_season(torneo_id: int, temporada: int) -> void:
	var standings = StandingsService.get_standings(torneo_id, temporada)
	var campeon_id := 0
	if not standings.is_empty():
		campeon_id = int(standings[0]["equipo_id"])

	# Registrar en temporadas
	DatabaseManager.execute("""
		INSERT OR IGNORE INTO temporadas (numero, torneo_id, estado)
		VALUES (%d, %d, 'activa')
	""" % [temporada, torneo_id])

	DatabaseManager.execute("""
		UPDATE temporadas SET estado = 'finalizada', campeon_id = %d,
			fecha_fin = CURRENT_TIMESTAMP
		WHERE torneo_id = %d AND numero = %d
	""" % [campeon_id, torneo_id, temporada])

	print("[CareerService] Temporada %d finalizada. Campeón: equipo %d" % [temporada, campeon_id])

## Inicia la siguiente temporada: crea entrada y genera calendario.
static func start_new_season(torneo_id: int, temporada_anterior: int) -> Dictionary:
	var nueva_temp := temporada_anterior + 1

	# Crear registro de temporada
	DatabaseManager.execute("""
		INSERT OR IGNORE INTO temporadas (numero, torneo_id, estado)
		VALUES (%d, %d, 'activa')
	""" % [nueva_temp, torneo_id])

	# Generar calendario nuevo
	var res = CalendarGenerator.generate_all_calendars(nueva_temp, 0)
	if not res["success"]:
		return {"success": false, "error": "Error generando calendario: " + res["error"]}

	return {"success": true, "nueva_temporada": nueva_temp}

## Registra la primera entrada de temporada si no existe (llamar al crear partida).
static func ensure_temporada_activa(torneo_id: int, temporada: int) -> void:
	DatabaseManager.execute("""
		INSERT OR IGNORE INTO temporadas (numero, torneo_id, estado)
		VALUES (%d, %d, 'activa')
	""" % [temporada, torneo_id])
