class_name StandingsService
extends RefCounted

## Orden de desempate determinista (5 niveles):
## 1. Puntos DESC  2. DG DESC  3. GF DESC  4. Victorias DESC  5. Nombre ASC
static func get_standings(torneo_id: int, temporada: int) -> Array:
	return DatabaseManager.fetch_rows("""
		SELECT
			eq.id   AS equipo_id,
			eq.nombre,
			COALESCE(s.partidos_jugados, 0)  AS pj,
			COALESCE(s.victorias,        0)  AS v,
			COALESCE(s.empates,          0)  AS empates,
			COALESCE(s.derrotas,         0)  AS d,
			COALESCE(s.goles_favor,      0)  AS gf,
			COALESCE(s.goles_contra,     0)  AS gc,
			COALESCE(s.goles_favor,  0) - COALESCE(s.goles_contra, 0) AS dg,
			COALESCE(s.puntos,           0)  AS pts
		FROM equipos eq
		LEFT JOIN estadisticas_liga s
			ON s.equipo_id = eq.id
			AND s.torneo_id = %d
			AND s.temporada = %d
		WHERE eq.liga_id = %d
		ORDER BY pts DESC, dg DESC, gf DESC, v DESC, eq.nombre ASC
	""" % [torneo_id, temporada, torneo_id])

## Guarda un snapshot de la clasificación actual para la jornada indicada.
static func save_jornada_snapshot(torneo_id: int, temporada: int, jornada: int) -> bool:
	var standings = get_standings(torneo_id, temporada)
	var s := true
	var posicion := 1
	for row in standings:
		s = s and DatabaseManager.execute("""
			INSERT OR REPLACE INTO posiciones_jornada
				(temporada, torneo_id, jornada, equipo_id, posicion,
				 puntos, partidos_jugados, victorias, empates, derrotas,
				 goles_favor, goles_contra)
			VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d)
		""" % [temporada, torneo_id, jornada,
			   int(row["equipo_id"]), posicion,
			   int(row["pts"]), int(row["pj"]), int(row["v"]),
			   int(row["empates"]), int(row["d"]),
			   int(row["gf"]), int(row["gc"])])
		posicion += 1
	return s

## Devuelve la posición de una jornada específica para un equipo.
static func get_posicion_en_jornada(equipo_id: int, torneo_id: int, temporada: int, jornada: int) -> int:
	var rows = DatabaseManager.fetch_rows("""
		SELECT posicion FROM posiciones_jornada
		WHERE equipo_id = %d AND torneo_id = %d AND temporada = %d AND jornada = %d
	""" % [equipo_id, torneo_id, temporada, jornada])
	if rows.is_empty(): return -1
	return int(rows[0]["posicion"])
