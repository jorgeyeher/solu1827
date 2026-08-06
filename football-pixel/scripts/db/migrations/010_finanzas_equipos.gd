extends RefCounted

func up() -> bool:
	var cols = {}
	for c in DatabaseManager.fetch_rows("PRAGMA table_info(equipos)"):
		cols[str(c.get("name", ""))] = true
	var ok = true
	if not cols.has("presupuesto"):
		ok = ok and DatabaseManager.execute("ALTER TABLE equipos ADD COLUMN presupuesto INTEGER DEFAULT 500000")
	if not cols.has("presupuesto_salarial"):
		ok = ok and DatabaseManager.execute("ALTER TABLE equipos ADD COLUMN presupuesto_salarial INTEGER DEFAULT 200000")
	return ok
