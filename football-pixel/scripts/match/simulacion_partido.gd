extends Control

const MENU_PARTIDA_SCENE := "res://scenes/career/menu_plantilla.tscn"

# --- 1. CABLES DE INTERFAZ ---
@onready var btn_pausa: Button = $Overlay/BtnPausa
@onready var label_local: Label = $Overlay/Scoreboard/ScoreMargin/ScoreRow/LocalBox/LabelLocal
@onready var label_goles_local: Label = $Overlay/Scoreboard/ScoreMargin/ScoreRow/LocalBox/ScorePanel/LabelGolesLocal
@onready var label_minuto: Label = $Overlay/Scoreboard/ScoreMargin/ScoreRow/CenterBox/LabelMinuto
@onready var label_periodo: Label = $Overlay/Scoreboard/ScoreMargin/ScoreRow/CenterBox/LabelPeriodo
@onready var label_visitante: Label = $Overlay/Scoreboard/ScoreMargin/ScoreRow/VisitanteBox/LabelVisitante
@onready var label_goles_visitante: Label = $Overlay/Scoreboard/ScoreMargin/ScoreRow/VisitanteBox/ScorePanel/LabelGolesVisitante
@onready var comentarios: Label = $Overlay/ComentariosPanel/ComentariosMargin/Comentarios
@onready var timer_partido: Timer = $TimerPartido 

# --- 2. VARIABLES DINÁMICAS DEL PARTIDO ---
var pausa_visual_activa := false
var minuto_actual = 0
var goles_local = 0
var goles_visita = 0

# NUEVAS LISTAS: Para saber quién anotó y quién asistió
var anotadores_partido = [] 
var asistentes_partido = []

# AHORA SON DINÁMICOS (Se llenan solos desde la Base de Datos)
var partido_id_actual = 0
var equipo_local_id = 0 
var equipo_visita_id = 0 
var torneo_actual_id = 1    # NUEVO: Para saber a qué liga sumarle los puntos
var temporada_actual = 1    # NUEVO: Para saber la temporada en curso

var titulares_local = []
var titulares_visita = []
var datos_local = {}  
var datos_visita = {} 

# --- 3. EL ARRANQUE ---
func _ready() -> void:
	configurar_estilos()
	
	label_goles_local.text = "0"
	label_goles_visitante.text = "0"
	label_minuto.text = "0'"
	label_periodo.text = "PREVIA"
	comentarios.text = "Buscando partido en el calendario..."
	
	btn_pausa.pressed.connect(_on_btn_pausa_pressed)
	
	# Magia Dinámica: Solo arranca si hay un partido en el calendario
	if cargar_proximo_partido():
		comentarios.text = "¡Los equipos saltan a la cancha!\nEl árbitro revisa su reloj..."
		cargar_titulares()
		timer_partido.wait_time = 1.0
		timer_partido.timeout.connect(procesar_minuto)
		timer_partido.start()
		label_periodo.text = "1A MITAD"
	else:
		comentarios.text = "No hay partidos pendientes para tu equipo en el calendario."

# --- 4. CONEXIÓN AL CALENDARIO ---
func cargar_proximo_partido() -> bool:
	# Toma el ID de tu equipo desde el GameManager
	var mi_equipo = GameManager.equipo_jugador_id
	
	# Busca el próximo partido NO JUGADO (jugado = 0) donde participe tu equipo
	var query = """
		SELECT id, equipo_local_id, equipo_visita_id, torneo_id, temporada
		FROM partidos
		WHERE (equipo_local_id = %d OR equipo_visita_id = %d)
		AND jugado = 0
		ORDER BY temporada ASC, jornada ASC
		LIMIT 1
	""" % [mi_equipo, mi_equipo]
	
	DatabaseManager.db.query(query)
	
	if DatabaseManager.db.query_result.size() > 0:
		var partido = DatabaseManager.db.query_result[0]
		partido_id_actual = int(partido["id"])
		equipo_local_id = int(partido["equipo_local_id"])
		equipo_visita_id = int(partido["equipo_visita_id"])
		torneo_actual_id = int(partido.get("torneo_id", 1))
		temporada_actual = int(partido.get("temporada", 1))
		return true
		
	return false

# --- 5. EL CEREBRO (MOTOR MATEMÁTICO) ---
func cargar_titulares() -> void:
	DatabaseManager.db.query("SELECT * FROM equipos WHERE id = " + str(equipo_local_id))
	if DatabaseManager.db.query_result.size() > 0:
		datos_local = DatabaseManager.db.query_result[0].duplicate(true)
		label_local.text = str(datos_local["nombre"]).left(12).to_upper()
		
	DatabaseManager.db.query("SELECT * FROM jugadores WHERE equipo_id = " + str(equipo_local_id) + " LIMIT 11")
	titulares_local = DatabaseManager.db.query_result.duplicate(true)
	
	DatabaseManager.db.query("SELECT * FROM equipos WHERE id = " + str(equipo_visita_id))
	if DatabaseManager.db.query_result.size() > 0:
		datos_visita = DatabaseManager.db.query_result[0].duplicate(true)
		label_visitante.text = str(datos_visita["nombre"]).left(12).to_upper()
		
	DatabaseManager.db.query("SELECT * FROM jugadores WHERE equipo_id = " + str(equipo_visita_id) + " LIMIT 11")
	titulares_visita = DatabaseManager.db.query_result.duplicate(true)

func procesar_minuto() -> void:
	if pausa_visual_activa: 
		return 
		
	minuto_actual += 1
	label_minuto.text = str(minuto_actual) + "'"
	
	if minuto_actual > 45:
		label_periodo.text = "2A MITAD"
		
	if titulares_local.size() > 0 and titulares_visita.size() > 0:
		simular_evento_real()
	else:
		if minuto_actual == 1:
			comentarios.text = "Advertencia: Equipos sin jugadores suficientes."

	if minuto_actual >= 90:
		timer_partido.stop()
		comentarios.text = "¡FINAL DEL PARTIDO!"
		
		# 1. Guardamos todo en la "mochila" del GameManager
		GameManager.ultimo_local = label_local.text
		GameManager.ultimo_visita = label_visitante.text
		GameManager.goles_local = goles_local
		GameManager.goles_visita = goles_visita
		
		# Simulamos stats por ahora (luego las calcularemos real)
		GameManager.posesion_local = randi_range(40, 60)
		GameManager.tiros_local = goles_local + randi_range(2, 6)
		GameManager.tiros_visita = goles_visita + randi_range(2, 6)
		GameManager.faltas_local = randi_range(5, 15)
		GameManager.faltas_visita = randi_range(5, 15)
		
		# Designamos un MVP al azar del equipo ganador
		var equipo_ganador = titulares_local if goles_local >= goles_visita else titulares_visita
		var mejor_jugador = equipo_ganador[randi() % equipo_ganador.size()]
		GameManager.mvp_nombre = str(mejor_jugador.get("nombre", "Jugador"))
		GameManager.mvp_posicion = str(mejor_jugador.get("posicion_principal", "DC"))
		GameManager.mvp_goles = randi_range(1, 2) if goles_local > 0 else 0
		GameManager.mvp_valoracion = randf_range(8.0, 9.9)
		
		# >>> EL ACTA ARBITRAL: ACTUALIZA LA BASE DE DATOS <<<
		_guardar_acta_arbitral()
		
		# 2. Hacemos el cambio de pantalla
		get_tree().change_scene_to_file("res://scenes/match/resumen_partido.tscn")

func _guardar_acta_arbitral() -> void:
	# 1. ACTUALIZAR EL PARTIDO (Ya se jugó y guardamos el marcador)
	var query_partido = "UPDATE partidos SET jugado = 1, goles_local = %d, goles_visita = %d WHERE id = %d" % [goles_local, goles_visita, partido_id_actual]
	DatabaseManager.db.query(query_partido)
	
	# 2. CALCULAR PUNTOS Y RESULTADOS
	var pts_local = 0
	var pts_visita = 0
	var vic_local = 0
	var vic_visita = 0
	var emp_local = 0
	var emp_visita = 0
	var der_local = 0
	var der_visita = 0
	
	if goles_local > goles_visita:
		pts_local = 3
		vic_local = 1
		der_visita = 1
	elif goles_visita > goles_local:
		pts_visita = 3
		vic_visita = 1
		der_local = 1
	else:
		pts_local = 1
		pts_visita = 1
		emp_local = 1
		emp_visita = 1
		
	# ====================================================================
	# 3. EL TRUCO: CREAR LAS FILAS SI ES SU PRIMER PARTIDO DE LA TEMPORADA
	# ====================================================================
	var query_crear_local = "INSERT OR IGNORE INTO estadisticas_liga (equipo_id, torneo_id, temporada) VALUES (%d, %d, %d)" % [equipo_local_id, torneo_actual_id, temporada_actual]
	DatabaseManager.db.query(query_crear_local)
	
	var query_crear_visita = "INSERT OR IGNORE INTO estadisticas_liga (equipo_id, torneo_id, temporada) VALUES (%d, %d, %d)" % [equipo_visita_id, torneo_actual_id, temporada_actual]
	DatabaseManager.db.query(query_crear_visita)
	# ====================================================================

	# 4. ENVIAR PUNTOS DEL LOCAL A LA TABLA DE LIGA
	var query_local = """
		UPDATE estadisticas_liga 
		SET partidos_jugados = partidos_jugados + 1,
			victorias = victorias + %d, empates = empates + %d, derrotas = derrotas + %d,
			goles_favor = goles_favor + %d, goles_contra = goles_contra + %d,
			puntos = puntos + %d
		WHERE equipo_id = %d AND torneo_id = %d AND temporada = %d
	""" % [vic_local, emp_local, der_local, goles_local, goles_visita, pts_local, equipo_local_id, torneo_actual_id, temporada_actual]
	DatabaseManager.db.query(query_local)
	
	# 5. ENVIAR PUNTOS DEL VISITANTE A LA TABLA DE LIGA
	var query_visita = """
		UPDATE estadisticas_liga 
		SET partidos_jugados = partidos_jugados + 1,
			victorias = victorias + %d, empates = empates + %d, derrotas = derrotas + %d,
			goles_favor = goles_favor + %d, goles_contra = goles_contra + %d,
			puntos = puntos + %d
		WHERE equipo_id = %d AND torneo_id = %d AND temporada = %d
	""" % [vic_visita, emp_visita, der_visita, goles_visita, goles_local, pts_visita, equipo_visita_id, torneo_actual_id, temporada_actual]
	DatabaseManager.db.query(query_visita)
	
	# ====================================================================
	# 6. ESTADÍSTICAS INDIVIDUALES DE JUGADORES
	# ====================================================================
	
	# A) Sumar 1 partido jugado a todos los titulares
	for jugador in titulares_local + titulares_visita:
		var id_jug = int(jugador["id"])
		DatabaseManager.db.query("UPDATE jugadores SET partidos_jugados = partidos_jugados + 1 WHERE id = %d" % id_jug)
	
	# B) Sumar los Goles
	for id_goleador in anotadores_partido:
		DatabaseManager.db.query("UPDATE jugadores SET goles = goles + 1 WHERE id = %d" % id_goleador)
		
	# C) Sumar las Asistencias
	for id_asistente in asistentes_partido:
		DatabaseManager.db.query("UPDATE jugadores SET asistencias = asistencias + 1 WHERE id = %d" % id_asistente)

	# D) Porterías en Cero (Bonus para el portero si no recibió gol)
	if goles_visita == 0 and titulares_local.size() > 0:
		var id_portero_local = int(titulares_local[0]["id"]) # Asumiendo que el índice 0 es el portero
		DatabaseManager.db.query("UPDATE jugadores SET porterias_cero = porterias_cero + 1 WHERE id = %d" % id_portero_local)

	if goles_local == 0 and titulares_visita.size() > 0:
		var id_portero_visita = int(titulares_visita[0]["id"])
		DatabaseManager.db.query("UPDATE jugadores SET porterias_cero = porterias_cero + 1 WHERE id = %d" % id_portero_visita)
	
	print("Acta arbitral y estadísticas individuales guardadas correctamente.")

func calcular_poder_equipo(plantilla: Array) -> float:
	var poder_total = 0.0
	for jugador in plantilla:
		var moral = float(jugador.get("moral", 80)) / 100.0
		var pase = float(jugador.get("pase_corto", 50))
		var control = float(jugador.get("control_balon", 50))
		var vision = float(jugador.get("vision_juego", 50))
		poder_total += (pase + control + vision) * moral
	return poder_total

func simular_evento_real() -> void:
	var poder_local = calcular_poder_equipo(titulares_local)
	var poder_visita = calcular_poder_equipo(titulares_visita)
	
	poder_local *= 1.10 
	
	poder_local += float(datos_local.get("reputacion", 50)) * 2.0
	poder_visita += float(datos_visita.get("reputacion", 50)) * 2.0
	
	var tactica_local = str(datos_local.get("estilo_tactico_base", "Equilibrado"))
	var tactica_visita = str(datos_visita.get("estilo_tactico_base", "Equilibrado"))
	
	if tactica_local == "Posesion": poder_local *= 1.15
	elif tactica_local == "Contraataque largo": poder_local *= 0.85
		
	if tactica_visita == "Posesion": poder_visita *= 1.15
	elif tactica_visita == "Contraataque largo": poder_visita *= 0.85

	var caos_local = randf_range(0.9, 1.1)
	var caos_visita = randf_range(0.9, 1.1)
	
	var total_poder = (poder_local * caos_local) + (poder_visita * caos_visita)
	if total_poder <= 0: total_poder = 1.0 
	
	var dado_posesion = randf_range(0, total_poder)
	
	if dado_posesion <= (poder_local * caos_local):
		intentar_disparo(titulares_local, titulares_visita, true)
	else:
		intentar_disparo(titulares_visita, titulares_local, false)

func intentar_disparo(atacantes: Array, defensores: Array, es_local: bool) -> void:
	var prob_ataque = 15
	var datos_atacante = datos_local if es_local else datos_visita
	var estilo_atacante = str(datos_atacante.get("estilo_tactico_base", "Equilibrado"))
	
	if estilo_atacante == "Contraataque largo":
		prob_ataque = 25 
		
	if randi_range(1, 100) > prob_ataque: return 
		
	var indice_aleatorio = randi() % atacantes.size()
	var tirador = atacantes[indice_aleatorio]
	var portero_rival = defensores[0] 
	
	var moral_tirador = float(tirador.get("moral", 80)) / 100.0
	var moral_portero = float(portero_rival.get("moral", 80)) / 100.0
	
	var fin = float(tirador.get("finalizacion", 50))
	var pot = float(tirador.get("potencia_tiro", 50))
	var ref = float(portero_rival.get("reflejos_gk", 50))
	var atj = float(portero_rival.get("atajadas_gk", 50))
	
	var poder_tiro = ((fin + pot) * moral_tirador) + randi_range(0, 20)
	var poder_atajada = ((ref + atj) * moral_portero) + randi_range(0, 20)
	
	var nombre_equipo = label_local.text if es_local else label_visitante.text
	var nombre_tirador = str(tirador.get("nombre", "Jugador"))
	
	if poder_tiro > poder_atajada:
		# 1. Elegimos un asistente al azar (que no sea el mismo que tiró)
		var posible_asistente = atacantes[randi() % atacantes.size()]
		var id_asistente = int(posible_asistente["id"])
		var id_tirador = int(tirador["id"])
		
		if id_asistente == id_tirador:
			id_asistente = 0 # Fue una jugada individual, sin asistencia

		# 2. Guardamos los IDs en nuestras listas para el Acta Arbitral
		anotadores_partido.append(id_tirador)
		if id_asistente > 0:
			asistentes_partido.append(id_asistente)

		if es_local:
			goles_local += 1
			label_goles_local.text = str(goles_local)
		else:
			goles_visita += 1
			label_goles_visitante.text = str(goles_visita)
		comentarios.text = "Minuto " + str(minuto_actual) + "\n¡GOL DE " + nombre_equipo + "!\nRemate implacable de " + nombre_tirador + "."
	else:
		comentarios.text = "Minuto " + str(minuto_actual) + "\n¡Disparo de " + nombre_tirador + "!\nPero el portero reacciona perfecto."

# --- 6. FUNCIONES DE ESTILO DE CODEX ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MENU_PARTIDA_SCENE)

func _on_btn_pausa_pressed() -> void:
	pausa_visual_activa = not pausa_visual_activa
	if pausa_visual_activa:
		label_periodo.text = "PAUSA"
		comentarios.text = "El árbitro detiene las acciones."
	else:
		label_periodo.text = "1A MITAD" if minuto_actual <= 45 else "2A MITAD"
		comentarios.text = "¡Se reanuda el partido!"

func configurar_estilos() -> void:
	apply_button_theme(btn_pausa, Color("f8c748"), Color("ffd861"), Color("e5a21f"), Color("3f2400"), Color("8d3d00"), 18, 6)
	btn_pausa.add_theme_font_size_override("font_size", 58)
	btn_pausa.add_theme_color_override("font_focus_color", Color("3f2400"))
	var tablero = $Overlay/Scoreboard
	var comentarios_panel = $Overlay/ComentariosPanel
	var panel_local = $Overlay/Scoreboard/ScoreMargin/ScoreRow/LocalBox/ScorePanel
	var panel_visitante = $Overlay/Scoreboard/ScoreMargin/ScoreRow/VisitanteBox/ScorePanel
	tablero.add_theme_stylebox_override("panel", make_style(Color("3f434d"), 6, Color("20242c"), 6))
	panel_local.add_theme_stylebox_override("panel", make_style(Color("262a34"), 4, Color("1a1e25"), 4))
	panel_visitante.add_theme_stylebox_override("panel", make_style(Color("262a34"), 4, Color("1a1e25"), 4))
	comentarios_panel.add_theme_stylebox_override("panel", make_style(Color("f7f7f7"), 0, Color("37333f"), 6))
	for label in [label_local, label_visitante]:
		label.add_theme_font_size_override("font_size", 30)
		label.add_theme_color_override("font_color", Color("f2f3f5"))
	for score in [label_goles_local, label_goles_visitante]:
		score.add_theme_font_size_override("font_size", 86)
		score.add_theme_color_override("font_color", Color("f8fbff"))
	label_minuto.add_theme_font_size_override("font_size", 94)
	label_minuto.add_theme_color_override("font_color", Color("ffb733"))
	label_periodo.add_theme_font_size_override("font_size", 34)
	label_periodo.add_theme_color_override("font_color", Color("ffb733"))
	comentarios.add_theme_font_size_override("font_size", 60)
	comentarios.add_theme_color_override("font_color", Color("26212b"))
	comentarios.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func apply_button_theme(boton: Button, normal: Color, hover: Color, pressed: Color, font_color: Color, border_color: Color, radius: int = 8, width: int = 2) -> void:
	boton.add_theme_stylebox_override("normal", make_style(normal, radius, border_color, width))
	boton.add_theme_stylebox_override("hover", make_style(hover, radius, border_color, width))
	boton.add_theme_stylebox_override("pressed", make_style(pressed, radius, border_color, width))
	boton.add_theme_color_override("font_color", font_color)
	boton.add_theme_color_override("font_hover_color", font_color)
	boton.add_theme_color_override("font_pressed_color", font_color)

func make_style(color: Color, radius: int = 0, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.border_width_bottom = width
	style.border_width_left = width
	style.border_width_right = width
	style.border_width_top = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
