extends Node

var db: SQLite
var db_name: String = "res://datos/PRUEBA.db"

func _ready() -> void:
	db = SQLite.new()
	db.path = db_name
	db.open_db()
	ensure_player_schema()

	print("Base de datos conectada con exito.")

func is_ready() -> bool:
	return db != null

func execute(query: String) -> bool:
	if not is_ready():
		push_error("La base de datos no esta lista.")
		return false

	db.error_message = ""
	db.query(query)
	var error_text = str(db.error_message).strip_edges().to_lower()
	if error_text != "" and error_text != "not an error":
		push_error("Fallo la consulta SQL: %s | %s" % [query, str(db.error_message)])
		return false

	return true

func fetch_rows(query: String) -> Array:
	if not execute(query):
		return []

	return db.query_result.duplicate(true)

func escape_text(value: String) -> String:
	return value.replace("'", "''")

func quote_identifier(identifier: String) -> String:
	return "\"%s\"" % identifier.replace("\"", "\"\"")

func ensure_player_schema() -> void:
	var columnas = fetch_rows("PRAGMA table_info(jugadores)")
	if columnas.is_empty():
		return

	var nombres := {}
	for columna in columnas:
		nombres[str(columna.get("name", ""))] = true

	if not nombres.has("pie preferido"):
		execute(
			"ALTER TABLE jugadores ADD COLUMN %s TEXT NOT NULL DEFAULT 'Diestro'" %
			quote_identifier("pie preferido")
		)
		nombres["pie preferido"] = true

	if not nombres.has("uso de pie malo"):
		execute(
			"ALTER TABLE jugadores ADD COLUMN %s INTEGER NOT NULL DEFAULT 50" %
			quote_identifier("uso de pie malo")
		)
		nombres["uso de pie malo"] = true

	if nombres.has("pie preferido") and nombres.has("pie_preferido"):
		execute(
			"""
			UPDATE jugadores
			SET %s = CASE
				WHEN pie_preferido = 'Derecho' THEN 'Diestro'
				WHEN pie_preferido = 'Izquierdo' THEN 'Zurdo'
				WHEN pie_preferido = 'Ambidiestro' THEN 'Ambidiestro'
				ELSE pie_preferido
			END
			WHERE pie_preferido IS NOT NULL
				AND TRIM(COALESCE(pie_preferido, '')) != ''
				AND (%s IS NULL OR TRIM(COALESCE(%s, '')) = '')
			""" % [
				quote_identifier("pie preferido"),
				quote_identifier("pie preferido"),
				quote_identifier("pie preferido")
			]
		)

	if nombres.has("uso de pie malo") and nombres.has("uso_pie_malo"):
		execute(
			"""
			UPDATE jugadores
			SET %s = uso_pie_malo
			WHERE uso_pie_malo IS NOT NULL
				AND (%s IS NULL OR %s = 50)
			""" % [
				quote_identifier("uso de pie malo"),
				quote_identifier("uso de pie malo"),
				quote_identifier("uso de pie malo")
			]
		)
