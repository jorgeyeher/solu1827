extends RefCounted

func up() -> bool:
	var cols = {}
	for c in DatabaseManager.fetch_rows("PRAGMA table_info(jugadores)"):
		cols[str(c.get("name", ""))] = true
	var ok = true
	if not cols.has("energia"):
		ok = ok and DatabaseManager.execute("ALTER TABLE jugadores ADD COLUMN energia INTEGER DEFAULT 80")
	if not cols.has("moral"):
		ok = ok and DatabaseManager.execute("ALTER TABLE jugadores ADD COLUMN moral INTEGER DEFAULT 70")
	# Inicializar con valores coherentes si la columna ya tenía datos
	if ok:
		DatabaseManager.execute("UPDATE jugadores SET energia = 80 WHERE energia IS NULL OR energia = 0")
		DatabaseManager.execute("UPDATE jugadores SET moral = 70 WHERE moral IS NULL OR moral = 0")
	return ok
