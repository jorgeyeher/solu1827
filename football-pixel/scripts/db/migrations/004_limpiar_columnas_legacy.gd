extends RefCounted

func up() -> bool:
	var cols = {}
	for c in DatabaseManager.fetch_rows("PRAGMA table_info(jugadores)"): 
		cols[str(c.get("name", ""))] = true
	
	var drop_candidates = ["pie preferido", "uso de pie malo", "media", "overall", "titular"]
	
	for c in drop_candidates:
		if cols.has(c):
			var res = DatabaseManager.execute("ALTER TABLE jugadores DROP COLUMN \"%s\"" % c)
			if not res:
				print("Warning: no se pudo hacer DROP COLUMN de %s (SQLite <= 3.35?)" % c)
	
	return true
