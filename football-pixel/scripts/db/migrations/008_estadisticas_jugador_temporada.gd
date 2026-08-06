extends RefCounted

func up() -> bool:
	return DatabaseManager.execute("""
		CREATE TABLE IF NOT EXISTS estadisticas_jugador_temporada (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			jugador_id INTEGER NOT NULL,
			equipo_id INTEGER NOT NULL,
			temporada INTEGER NOT NULL,
			torneo_id INTEGER NOT NULL,
			partidos_jugados INTEGER DEFAULT 0,
			goles INTEGER DEFAULT 0,
			asistencias INTEGER DEFAULT 0,
			porterias_cero INTEGER DEFAULT 0,
			minutos_jugados INTEGER DEFAULT 0,
			UNIQUE(jugador_id, temporada, torneo_id)
		)
	""")
