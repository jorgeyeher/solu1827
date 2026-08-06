extends RefCounted

func up() -> bool:
	return DatabaseManager.execute("""
		CREATE TABLE IF NOT EXISTS movimientos_financieros (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			equipo_id INTEGER NOT NULL,
			temporada INTEGER NOT NULL,
			jornada INTEGER NOT NULL,
			partido_id INTEGER DEFAULT 0,
			tipo TEXT NOT NULL,
			descripcion TEXT NOT NULL,
			cantidad INTEGER NOT NULL,
			fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(equipo_id, temporada, jornada, tipo, partido_id)
		)
	""")
