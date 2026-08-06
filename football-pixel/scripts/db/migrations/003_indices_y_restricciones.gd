extends RefCounted

func up() -> bool:
	var s = true
	s = s and DatabaseManager.execute("CREATE INDEX IF NOT EXISTS idx_jugadores_equipo ON jugadores (equipo_id)")
	s = s and DatabaseManager.execute("CREATE INDEX IF NOT EXISTS idx_partidos_torneo ON partidos (torneo_id, temporada)")
	s = s and DatabaseManager.execute("CREATE UNIQUE INDEX IF NOT EXISTS uidx_partido_unico ON partidos (temporada, torneo_id, jornada, equipo_local_id, equipo_visita_id)")
	return s
