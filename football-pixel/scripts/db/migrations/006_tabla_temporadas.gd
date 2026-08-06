extends RefCounted

func up() -> bool:
	return DatabaseManager.execute("""
		CREATE TABLE IF NOT EXISTS temporadas (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			numero INTEGER NOT NULL,
			torneo_id INTEGER NOT NULL,
			estado TEXT DEFAULT 'activa',
			campeon_id INTEGER,
			fecha_inicio DATETIME DEFAULT CURRENT_TIMESTAMP,
			fecha_fin DATETIME,
			UNIQUE(numero, torneo_id)
		)
	""")
