extends Control

@onready var btn_generar = $Button

func _ready() -> void:
	btn_generar.pressed.connect(ejecutar_sorteo)

func ejecutar_sorteo() -> void:
	print("Iniciando el sorteo de calendarios...")

	var ligas = DatabaseManager.fetch_rows("SELECT id, nombre FROM ligas")

	for liga in ligas:
		var liga_id = int(liga["id"])
		var liga_nombre = str(liga["nombre"])
		var delete_query = "DELETE FROM partidos WHERE temporada = 1 AND torneo_id = %d" % liga_id
		if not DatabaseManager.execute(delete_query):
			print("No se pudo limpiar el calendario de la liga: ", liga_nombre)
			continue

		generar_round_robin(liga_id, 1)
		print("Calendario de '", liga_nombre, "' generado con exito.")

	print("Todos los calendarios europeos estan listos.")

func generar_round_robin(liga_id: int, temporada: int) -> void:
	var query = "SELECT id FROM equipos WHERE liga_id = %d" % liga_id
	var filas = DatabaseManager.fetch_rows(query)
	var equipos: Array[int] = []

	for fila in filas:
		equipos.append(int(fila["id"]))

	var num_equipos = equipos.size()
	if num_equipos < 2:
		print("La liga ", liga_id, " no tiene suficientes equipos para generar calendario.")
		return

	if num_equipos % 2 != 0:
		equipos.append(-1)
		num_equipos += 1

	var num_jornadas = num_equipos - 1
	var mitad = int(num_equipos / 2.0)

	for i in range(num_jornadas):
		var jornada_actual = i + 1

		for j in range(mitad):
			var local = equipos[j]
			var visita = equipos[num_equipos - 1 - j]

			if local == -1 or visita == -1:
				continue

			if j % 2 == 1 or (i % 2 == 1 and j == 0):
				guardar_partido(liga_id, temporada, jornada_actual, visita, local)
				guardar_partido(liga_id, temporada, jornada_actual + num_jornadas, local, visita)
			else:
				guardar_partido(liga_id, temporada, jornada_actual, local, visita)
				guardar_partido(liga_id, temporada, jornada_actual + num_jornadas, visita, local)

		var ultimo = equipos.pop_back()
		equipos.insert(1, ultimo)

func guardar_partido(torneo_id: int, temporada: int, jornada: int, local: int, visita: int) -> void:
	var query = "INSERT INTO partidos (torneo_id, temporada, jornada, equipo_local_id, equipo_visita_id) VALUES (%d, %d, %d, %d, %d)" % [
		torneo_id,
		temporada,
		jornada,
		local,
		visita
	]
	DatabaseManager.execute(query)
