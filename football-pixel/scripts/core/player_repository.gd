class_name PlayerRepository
extends RefCounted

static var _cached_columns: Dictionary = {}

static func _ensure_cache() -> void:
	if not _cached_columns.is_empty():
		return
	
	var columnas = DatabaseManager.fetch_rows("PRAGMA table_info(jugadores)")
	for columna in columnas:
		var name = str(columna.get("name", ""))
		if name != "" and int(columna.get("pk", 0)) == 0:
			var type = str(columna.get("type", "")).to_upper()
			var not_null = (int(columna.get("notnull", 0)) == 1)
			_cached_columns[name] = {
				"type": type,
				"notnull": not_null
			}

static func clear_cache() -> void:
	_cached_columns.clear()

static func insert_player(jugador: Dictionary) -> Dictionary:
	_ensure_cache()
	
	var n_jugador = _normalize_dict(jugador)
	
	if not n_jugador.has("equipo_id") or not n_jugador.has("nombre"):
		return {"success": false, "error": "Faltan campos obligatorios: equipo_id o nombre."}
		
	var columnas: Array[String] = []
	var valores_sql: Array[String] = []
	
	for nombre_col in _cached_columns.keys():
		var def = _cached_columns[nombre_col]
		var valor = _resolver_valor(nombre_col, def, n_jugador)
		
		if valor == null and not def["notnull"]:
			continue
			
		columnas.append(nombre_col)
		valores_sql.append(_a_sql_literal(valor))
		
	if columnas.is_empty():
		return {"success": false, "error": "No hay columnas validas para insertar."}
		
	var columnas_sql: Array[String] = []
	for c in columnas:
		columnas_sql.append(DatabaseManager.quote_identifier(c))
		
	var query = "INSERT INTO jugadores (%s) VALUES (%s)" % [",".join(columnas_sql), ",".join(valores_sql)]
	if DatabaseManager.execute(query):
		return {"success": true, "error": ""}
	else:
		return {"success": false, "error": "Error al insertar en SQLite."}

static func _normalize_dict(jugador: Dictionary) -> Dictionary:
	var n = jugador.duplicate()
	
	if n.has("media"): n["calidad_actual"] = n["media"]
	if n.has("overall"): n["calidad_actual"] = n["overall"]
	if n.has("potencial"): n["calidad_potencial"] = n["potencial"]
	if n.has("titular"): n["es_titular"] = n["titular"]
	
	if n.has("pie preferido") and not n.has("pie_preferido"):
		n["pie_preferido"] = n["pie preferido"]
	if n.has("pie_preferido") and not n.has("pie preferido"):
		n["pie preferido"] = n["pie_preferido"]
		
	if n.has("uso de pie malo") and not n.has("uso_pie_malo"):
		n["uso_pie_malo"] = n["uso de pie malo"]
	if n.has("uso_pie_malo") and not n.has("uso de pie malo"):
		n["uso de pie malo"] = n["uso_pie_malo"]
		
	return n

static func _resolver_valor(nombre_col: String, def: Dictionary, jugador: Dictionary):
	if jugador.has(nombre_col):
		return jugador[nombre_col]
		
	if def["notnull"]:
		if "INT" in def["type"]: return 0
		if "REAL" in def["type"] or "FLOA" in def["type"] or "DOUB" in def["type"]: return 0.0
		return ""
		
	return null

static func _a_sql_literal(valor) -> String:
	if valor == null:
		return "NULL"
	if valor is String:
		return "'%s'" % DatabaseManager.escape_text(valor)
	if valor is bool:
		return "1" if valor else "0"
	return str(valor)
