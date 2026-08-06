class_name DatabaseMigrator
extends RefCounted

const MIGRATIONS_DIR = "res://scripts/db/migrations/"

static func run_migrations() -> void:
	print("Ejecutando migraciones...")
	_ensure_migrations_table()
	
	var dir = DirAccess.open(MIGRATIONS_DIR)
	if not dir:
		push_error("No se encontro el directorio de migraciones: " + MIGRATIONS_DIR)
		return
		
	var archivos: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			archivos.append(file_name)
		file_name = dir.get_next()
		
	archivos.sort()
	
	for script_file in archivos:
		var version_str = script_file.get_slice("_", 0)
		if not version_str.is_valid_int(): continue
		
		var version = int(version_str)
		if version == 0:
			continue
			
		if _is_migration_applied(version):
			continue
			
		print("Aplicando migracion: ", script_file)
		var script = load(MIGRATIONS_DIR + script_file).new()
		
		DatabaseManager.execute("BEGIN;")
		
		var success = true
		if script.has_method("up"):
			success = script.up()
		else:
			push_error("La migracion %s no tiene metodo up()" % script_file)
			success = false
			
		if success:
			if _record_migration(version, script_file):
				DatabaseManager.execute("COMMIT;")
				print("Migracion %d aplicada exitosamente." % version)
			else:
				DatabaseManager.execute("ROLLBACK;")
				push_error("Error al registrar migracion %d. ROLLBACK ejecutado." % version)
				break
		else:
			DatabaseManager.execute("ROLLBACK;")
			push_error("Error en la logica de migracion %d. ROLLBACK ejecutado." % version)
			break

static func _ensure_migrations_table() -> void:
	DatabaseManager.execute("""
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version INTEGER PRIMARY KEY,
			name TEXT NOT NULL,
			applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	""")

static func _is_migration_applied(version: int) -> bool:
	var rows = DatabaseManager.fetch_rows("SELECT version FROM schema_migrations WHERE version = %d" % version)
	return rows.size() > 0

static func _record_migration(version: int, name: String) -> bool:
	var safe_name = DatabaseManager.escape_text(name)
	return DatabaseManager.execute("INSERT INTO schema_migrations (version, name) VALUES (%d, '%s')" % [version, safe_name])
