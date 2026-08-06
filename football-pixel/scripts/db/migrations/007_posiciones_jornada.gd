extends RefCounted

func up() -> bool:
	return DatabaseManager.execute("""
		CREATE TABLE IF NOT EXISTS posiciones_jornada (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			temporada INTEGER NOT NULL,
			torneo_id INTEGER NOT NULL,
			jornada INTEGER NOT NULL,
			equipo_id INTEGER NOT NULL,
			posicion INTEGER NOT NULL,
			puntos INTEGER DEFAULT 0,
			partidos_jugados INTEGER DEFAULT 0,
			victorias INTEGER DEFAULT 0,
			empates INTEGER DEFAULT 0,
			derrotas INTEGER DEFAULT 0,
			goles_favor INTEGER DEFAULT 0,
			goles_contra INTEGER DEFAULT 0,
			UNIQUE(temporada, torneo_id, jornada, equipo_id)
		)
	""")
