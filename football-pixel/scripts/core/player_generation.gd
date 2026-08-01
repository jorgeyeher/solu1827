class_name PlayerGeneration
extends RefCounted

const SQUAD_TARGET := 23

const SQUAD_TEMPLATE: Array[String] = [
	"POR",
	"LD", "DFC", "DFC", "LI",
	"MCD", "MC", "MC",
	"ED", "EI",
	"DC",
	"POR",
	"LD", "DFC", "DFC", "LI",
	"MCD", "MC",
	"MCO",
	"ED", "EI",
	"DC", "DC"
]

const NOMBRES: Array[String] = [
	"Carlos", "Miguel", "Diego", "Javier", "Luis", "Andres", "Mateo", "Sergio", "Pedro", "Ivan",
	"Daniel", "Hugo", "Marco", "Raul", "Tomas", "Adrian", "Pablo", "Bruno", "Thiago", "Nicolas",
	"Gabriel", "Emilio", "Victor", "Julian", "Enzo", "Ruben", "Alonso", "Dario", "Martin", "Gael"
]

const APELLIDOS: Array[String] = [
	"Ramirez", "Lopez", "Garcia", "Hernandez", "Santos", "Vega", "Navarro", "Mendoza", "Silva", "Castro",
	"Rojas", "Suarez", "Torres", "Campos", "Aguilar", "Medina", "Ortega", "Paredes", "Cruz", "Ibarra",
	"Guerrero", "Delgado", "Vargas", "Morales", "Salazar", "Molina", "Reyes", "Farias", "Herrera", "Nunez"
]

const ESTILOS_POR_POSICION := {
	"POR": ["Reflejos", "Juego aereo", "Atajador de penales"],
	"LD": ["Rapido", "Ofensivo", "Marcador"],
	"LI": ["Rapido", "Ofensivo", "Marcador"],
	"DFC": ["Fuerte", "Anticipacion", "Juego aereo"],
	"MCD": ["Recuperador", "Equilibrado", "Pulmon"],
	"MC": ["Creador", "Equilibrado", "Pulmon"],
	"MCO": ["Creativo", "Tecnico", "Visionario"],
	"ED": ["Regateador", "Vertical", "Velocista"],
	"EI": ["Regateador", "Vertical", "Velocista"],
	"DC": ["Definidor", "Area", "Potente"]
}

const PIES_POR_POSICION := {
	"POR": {"Diestro": 62, "Zurdo": 23, "Ambidiestro": 15},
	"DFC": {"Diestro": 60, "Zurdo": 22, "Ambidiestro": 18},
	"LD": {"Diestro": 74, "Zurdo": 10, "Ambidiestro": 16},
	"LI": {"Diestro": 18, "Zurdo": 66, "Ambidiestro": 16},
	"MCD": {"Diestro": 57, "Zurdo": 23, "Ambidiestro": 20},
	"MC": {"Diestro": 54, "Zurdo": 22, "Ambidiestro": 24},
	"MCO": {"Diestro": 50, "Zurdo": 24, "Ambidiestro": 26},
	"ED": {"Diestro": 70, "Zurdo": 12, "Ambidiestro": 18},
	"EI": {"Diestro": 15, "Zurdo": 65, "Ambidiestro": 20},
	"DC": {"Diestro": 58, "Zurdo": 20, "Ambidiestro": 22}
}

static func build_player(equipo_id: int, nombre_equipo: String, reputacion: int, orden_plantilla: int) -> Dictionary:
	var posicion = SQUAD_TEMPLATE[orden_plantilla % SQUAD_TEMPLATE.size()]
	var edad = randi_range(16, 36)
	var calidad_potencial = calcular_potencial(reputacion)
	var calidad_actual = calcular_calidad_actual(calidad_potencial, edad)
	var pie_preferido = obtener_pie_preferido(posicion)
	var uso_pie_malo = obtener_uso_pie_malo(posicion, pie_preferido)
	var stats = generar_atributos(calidad_actual, posicion)

	var jugador := {
		"equipo_id": equipo_id,
		"nombre": "%s %s" % [NOMBRES[randi() % NOMBRES.size()], APELLIDOS[randi() % APELLIDOS.size()]],
		"posicion_principal": posicion,
		"estilo_juego": obtener_estilo(posicion),
		"edad": edad,
		"dorsal": obtener_dorsal(orden_plantilla, posicion),
		"media": calidad_actual,
		"overall": calidad_actual,
		"calidad_actual": calidad_actual,
		"potencial": calidad_potencial,
		"calidad_potencial": calidad_potencial,
		"pie preferido": pie_preferido,
		"pie_preferido": pie_preferido,
		"uso de pie malo": uso_pie_malo,
		"uso_pie_malo": uso_pie_malo,
		"nacionalidad": "Internacional",
		"club_origen": nombre_equipo,
		"valor": calidad_actual * 150000,
		"salario": calidad_actual * 1500,
		"titular": 1 if orden_plantilla < 11 else 0,
		"lesionado": 0,
		"energia": 100,
		"moral": randi_range(75, 100)
	}

	jugador.merge(stats)
	return jugador

static func calcular_potencial(reputacion: int) -> int:
	var modificador_club = int((reputacion - 50) / 2.0)
	return clampi(60 + modificador_club + randi_range(-5, 10), 55, 95)

static func calcular_calidad_actual(calidad_potencial: int, edad: int) -> int:
	var calidad_actual = calidad_potencial
	if edad < 24:
		calidad_actual = calidad_potencial - ((24 - edad) * randi_range(2, 4))
	elif edad > 30:
		calidad_actual = calidad_potencial - ((edad - 30) * randi_range(1, 3))
	return clampi(calidad_actual, 40, calidad_potencial)

static func obtener_estilo(posicion: String) -> String:
	var estilos: Array = ESTILOS_POR_POSICION.get(posicion, ["Equilibrado"])
	return str(estilos[randi() % estilos.size()])

static func obtener_pie_preferido(posicion: String) -> String:
	var distribucion: Dictionary = PIES_POR_POSICION.get(
		posicion,
		{"Diestro": 58, "Zurdo": 22, "Ambidiestro": 20}
	)
	var tirada := randi() % 100
	var acumulado := 0

	for pie in ["Diestro", "Zurdo", "Ambidiestro"]:
		acumulado += int(distribucion.get(pie, 0))
		if tirada < acumulado:
			return pie

	return "Diestro"

static func obtener_uso_pie_malo(posicion: String, pie_preferido: String) -> int:
	if pie_preferido == "Ambidiestro":
		return 99

	match posicion:
		"POR", "DFC":
			return randi_range(35, 72)
		"LD", "LI", "MCD":
			return randi_range(40, 76)
		"MC":
			return randi_range(48, 82)
		"MCO":
			return randi_range(55, 88)
		"ED", "EI":
			return randi_range(45, 86)
		"DC":
			return randi_range(42, 84)
		_:
			return randi_range(40, 80)

static func obtener_dorsal(orden_plantilla: int, posicion: String) -> int:
	var dorsales_base := {
		"POR": [1, 13, 25],
		"LD": [2, 22],
		"DFC": [3, 4, 5, 15],
		"LI": [12, 16],
		"MCD": [6, 14],
		"MC": [8, 17, 18],
		"MCO": [10, 20],
		"ED": [7, 19],
		"EI": [11, 21],
		"DC": [9, 23, 24]
	}
	var opciones: Array = dorsales_base.get(posicion, [30])
	if orden_plantilla < opciones.size():
		return int(opciones[orden_plantilla])
	return 30 + orden_plantilla

static func generar_atributos(calidad_actual: int, posicion: String) -> Dictionary:
	var base = int(calidad_actual * 0.8)
	var stats := {}

	var campos_jugador = [
		"contacto_fisico", "marcaje", "actitud_ofensiva", "actitud_defensiva", "regate",
		"control_balon", "pase_corto", "pase_largo", "finalizacion", "potencia_tiro",
		"efecto", "tiro_larga_distancia", "cabeceo", "aceleracion", "velocidad", "fuerza",
		"resistencia", "salto", "sacrificio", "determinacion", "ambicion", "vision_juego",
		"posicionamiento", "consistencia"
	]
	var campos_portero = [
		"reflejos_gk", "atajadas_gk", "despeje_gk", "cobertura_gk", "posicionamiento_gk"
	]

	for campo in campos_jugador + campos_portero:
		stats[campo] = base + randi_range(-5, 5)

	match posicion:
		"POR":
			for campo in campos_portero:
				stats[campo] = clampi(calidad_actual + randi_range(-2, 5), 1, 99)
			stats["velocidad"] = 30
			stats["aceleracion"] = 30
			stats["finalizacion"] = 15
		"DFC":
			stats["marcaje"] = calidad_actual + randi_range(0, 5)
			stats["fuerza"] = calidad_actual + randi_range(0, 5)
			stats["cabeceo"] = calidad_actual + randi_range(-2, 5)
			stats["actitud_defensiva"] = calidad_actual + randi_range(0, 5)
			stats["finalizacion"] = base - 20
		"LD", "LI":
			stats["velocidad"] = calidad_actual + randi_range(0, 5)
			stats["aceleracion"] = calidad_actual + randi_range(0, 5)
			stats["resistencia"] = calidad_actual + randi_range(0, 5)
			stats["pase_corto"] = calidad_actual + randi_range(-5, 2)
		"MCD", "MC":
			stats["pase_corto"] = calidad_actual + randi_range(0, 5)
			stats["vision_juego"] = calidad_actual + randi_range(-2, 5)
			stats["resistencia"] = calidad_actual + randi_range(0, 5)
			stats["control_balon"] = calidad_actual + randi_range(-2, 5)
		"MCO":
			stats["pase_corto"] = calidad_actual + randi_range(0, 5)
			stats["vision_juego"] = calidad_actual + randi_range(0, 6)
			stats["regate"] = calidad_actual + randi_range(0, 5)
			stats["tiro_larga_distancia"] = calidad_actual + randi_range(-2, 5)
		"ED", "EI":
			stats["velocidad"] = calidad_actual + randi_range(2, 6)
			stats["aceleracion"] = calidad_actual + randi_range(2, 6)
			stats["regate"] = calidad_actual + randi_range(0, 5)
			stats["efecto"] = calidad_actual + randi_range(-2, 5)
		"DC":
			stats["finalizacion"] = calidad_actual + randi_range(2, 6)
			stats["actitud_ofensiva"] = calidad_actual + randi_range(0, 5)
			stats["potencia_tiro"] = calidad_actual + randi_range(0, 5)
			stats["marcaje"] = base - 20

	for key in stats.keys():
		stats[key] = clampi(int(stats[key]), 1, 99)

	return stats
