extends Node

var db: SQLite
var db_name: String = "res://datos/PRUEBA.db"

func _ready() -> void:
	db = SQLite.new()
	db.path = db_name
	db.open_db()
	DatabaseMigrator.run_migrations()
	PlayerRepository.clear_cache()
	print("Base de datos conectada con exito.")

func connect_to_db(new_path: String) -> void:
	if db != null:
		db.close_db()
	db_name = new_path
	db.path = db_name
	db.open_db()
	DatabaseMigrator.run_migrations()
	PlayerRepository.clear_cache()
	print("Base de datos conectada: ", new_path)

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


