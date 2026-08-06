extends RefCounted

func up() -> bool:
	var s = true
	var cols = {}
	var r = DatabaseManager.fetch_rows("PRAGMA table_info(jugadores)")
	for c in r: cols[str(c.get("name", ""))] = true

	if cols.has("pie preferido"):
		s = s and DatabaseManager.execute("UPDATE jugadores SET pie_preferido = \"pie preferido\" WHERE \"pie preferido\" IS NOT NULL AND pie_preferido IS NULL")
		
	s = s and DatabaseManager.execute("UPDATE jugadores SET pie_preferido = CASE WHEN pie_preferido = 'Derecho' THEN 'Diestro' WHEN pie_preferido = 'Izquierdo' THEN 'Zurdo' ELSE pie_preferido END")
		
	if cols.has("uso de pie malo"):
		s = s and DatabaseManager.execute("UPDATE jugadores SET uso_pie_malo = \"uso de pie malo\" WHERE \"uso de pie malo\" IS NOT NULL AND uso_pie_malo IS NULL")
		
	if cols.has("media"):
		s = s and DatabaseManager.execute("UPDATE jugadores SET calidad_actual = media WHERE media IS NOT NULL AND calidad_actual IS NULL")
	if cols.has("overall"):
		s = s and DatabaseManager.execute("UPDATE jugadores SET calidad_actual = overall WHERE overall IS NOT NULL AND (calidad_actual IS NULL OR calidad_actual = 0)")
	
	if cols.has("titular"):
		s = s and DatabaseManager.execute("UPDATE jugadores SET es_titular = titular WHERE titular IS NOT NULL AND (es_titular IS NULL OR es_titular = 0)")
		
	s = s and DatabaseManager.execute("UPDATE jugadores SET dorsal = 99 WHERE dorsal IS NULL")
		
	return s
