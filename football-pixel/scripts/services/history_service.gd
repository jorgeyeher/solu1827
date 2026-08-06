class_name HistoryService
extends RefCounted

## Historial de partidos jugados por un club (más recientes primero).
static func get_historial_club(equipo_id: int, limite: int = 30) -> Array:
	return DatabaseManager.fetch_rows("""
		SELECT
			p.id, p.jornada, p.temporada, p.torneo_id,
			p.goles_local, p.goles_visita,
			el.nombre AS local_nombre,
			ev.nombre AS visita_nombre,
			l.nombre  AS liga_nombre,
			CASE
				WHEN p.equipo_local_id = %d THEN 'local'
				ELSE 'visitante'
			END AS condicion
		FROM partidos p
		JOIN equipos el ON el.id = p.equipo_local_id
		JOIN equipos ev ON ev.id = p.equipo_visita_id
		JOIN ligas   l  ON l.id  = p.torneo_id
		WHERE (p.equipo_local_id = %d OR p.equipo_visita_id = %d)
		  AND p.jugado = 1
		ORDER BY p.temporada DESC, p.jornada DESC
		LIMIT %d
	""" % [equipo_id, equipo_id, equipo_id, limite])

## Devuelve el resultado desde la perspectiva del equipo (victoria/empate/derrota).
static func get_resultado_para_equipo(partido: Dictionary, equipo_id: int) -> String:
	var gl = int(partido.get("goles_local", 0))
	var gv = int(partido.get("goles_visita", 0))
	var es_local = (str(partido.get("condicion", "")) == "local")
	var goles_mi    = gl if es_local else gv
	var goles_rival = gv if es_local else gl
	if goles_mi > goles_rival:   return "victoria"
	elif goles_mi < goles_rival: return "derrota"
	return "empate"

## Campeones de temporadas anteriores.
static func get_campeones() -> Array:
	return DatabaseManager.fetch_rows("""
		SELECT t.numero AS temporada, l.nombre AS liga, eq.nombre AS campeon
		FROM temporadas t
		JOIN equipos eq ON eq.id = t.campeon_id
		JOIN ligas   l  ON l.id  = t.torneo_id
		WHERE t.estado = 'finalizada'
		ORDER BY t.numero DESC
	""")

## Estadísticas del club por temporada (desde estadisticas_liga).
static func get_stats_club_por_temporada(equipo_id: int) -> Array:
	return DatabaseManager.fetch_rows("""
		SELECT
			s.temporada,
			l.nombre AS liga,
			SUM(s.partidos_jugados) AS pj,
			SUM(s.victorias)        AS v,
			SUM(s.empates)          AS empates,
			SUM(s.derrotas)         AS d,
			SUM(s.goles_favor)      AS gf,
			SUM(s.goles_contra)     AS gc,
			SUM(s.puntos)           AS pts
		FROM estadisticas_liga s
		JOIN ligas l ON l.id = s.torneo_id
		WHERE s.equipo_id = %d
		GROUP BY s.temporada, s.torneo_id
		ORDER BY s.temporada DESC
	""" % equipo_id)

## Top goleadores de una temporada y torneo.
static func get_top_goleadores(torneo_id: int, temporada: int, limite: int = 5) -> Array:
	return DatabaseManager.fetch_rows("""
		SELECT
			j.nombre,
			eq.nombre AS equipo,
			ejt.goles,
			ejt.asistencias,
			ejt.partidos_jugados
		FROM estadisticas_jugador_temporada ejt
		JOIN jugadores j  ON j.id  = ejt.jugador_id
		JOIN equipos  eq ON eq.id = ejt.equipo_id
		WHERE ejt.torneo_id = %d AND ejt.temporada = %d
		ORDER BY ejt.goles DESC, ejt.asistencias DESC
		LIMIT %d
	""" % [torneo_id, temporada, limite])

## Estadísticas de un jugador en todas sus temporadas.
static func get_stats_jugador_completas(jugador_id: int) -> Array:
	return DatabaseManager.fetch_rows("""
		SELECT
			ejt.temporada,
			l.nombre AS liga,
			ejt.partidos_jugados, ejt.goles, ejt.asistencias,
			ejt.porterias_cero, ejt.minutos_jugados
		FROM estadisticas_jugador_temporada ejt
		JOIN ligas l ON l.id = ejt.torneo_id
		WHERE ejt.jugador_id = %d
		ORDER BY ejt.temporada DESC
	""" % jugador_id)
