extends RefCounted

func up() -> bool:
	var success = true
	var current_columns = {}
	var cols = DatabaseManager.fetch_rows("PRAGMA table_info(jugadores)")
	for c in cols:
		current_columns[str(c.get("name", ""))] = true

	var expected = {
		"calidad_actual": "INTEGER",
		"calidad_potencial": "INTEGER",
		"es_titular": "INTEGER DEFAULT 0",
		"pie_preferido": "TEXT",
		"uso_pie_malo": "INTEGER",
		"dorsal": "INTEGER"
	}

	for col in expected.keys():
		if not current_columns.has(col):
			success = success and DatabaseManager.execute("ALTER TABLE jugadores ADD COLUMN %s %s" % [col, expected[col]])

	return success
