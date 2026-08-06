class_name FinanceService
extends RefCounted

## Registra ingresos y premios de un partido.
## Es idempotente gracias a UNIQUE(equipo_id, temporada, jornada, tipo, partido_id).
static func registrar_resultado_partido(
	equipo_id: int, temporada: int, jornada: int,
	partido_id: int, es_local: bool, resultado: String
) -> bool:
	var s = true

	# Ingresos de taquilla solo como local
	if es_local:
		s = s and _insert(equipo_id, temporada, jornada, partido_id, "ingreso",
			"Taquilla local - Jornada %d" % jornada, CareerConfig.INGRESO_LOCAL_BASE)

	# Premio por resultado
	var premio := 0
	var desc   := ""
	match resultado:
		"victoria":
			premio = CareerConfig.PREMIO_VICTORIA
			desc   = "Premio por victoria - Jornada %d" % jornada
		"empate":
			premio = CareerConfig.PREMIO_EMPATE
			desc   = "Premio por empate - Jornada %d" % jornada

	if premio > 0:
		s = s and _insert(equipo_id, temporada, jornada, partido_id, "premio", desc, premio)

	return s

## Registra pago de salarios de la plantilla para la jornada.
static func pagar_salarios(equipo_id: int, temporada: int, jornada: int) -> bool:
	var filas = DatabaseManager.fetch_rows(
		"SELECT COALESCE(SUM(salario), 0) AS total FROM jugadores WHERE equipo_id = %d" % equipo_id)
	if filas.is_empty(): return true
	var total := int(filas[0].get("total", 0))
	if total <= 0: return true
	return _insert(equipo_id, temporada, jornada, 0, "salario",
		"Salarios plantilla - Jornada %d" % jornada, -total)

## Registra el coste operativo fijo de la jornada.
static func registrar_costo_operativo(equipo_id: int, temporada: int, jornada: int) -> bool:
	return _insert(equipo_id, temporada, jornada, 0, "gasto",
		"Coste operativo - Jornada %d" % jornada, -CareerConfig.COSTO_OPERATIVO_JORNADA)

## Calcula el saldo actual sumando todos los movimientos.
static func get_saldo_actual(equipo_id: int) -> int:
	var filas = DatabaseManager.fetch_rows(
		"SELECT COALESCE(SUM(cantidad), 0) AS total FROM movimientos_financieros WHERE equipo_id = %d" % equipo_id)
	if filas.is_empty(): return 0
	return int(filas[0].get("total", 0))

## Devuelve los últimos movimientos del club (más recientes primero).
static func get_ultimos_movimientos(equipo_id: int, limite: int = 10) -> Array:
	return DatabaseManager.fetch_rows("""
		SELECT tipo, descripcion, cantidad, fecha
		FROM movimientos_financieros
		WHERE equipo_id = %d
		ORDER BY id DESC LIMIT %d
	""" % [equipo_id, limite])

# ----------------------------------------------------------------
static func _insert(
	equipo_id: int, temporada: int, jornada: int,
	partido_id: int, tipo: String, descripcion: String, cantidad: int
) -> bool:
	return DatabaseManager.execute("""
		INSERT OR IGNORE INTO movimientos_financieros
			(equipo_id, temporada, jornada, partido_id, tipo, descripcion, cantidad)
		VALUES (%d, %d, %d, %d, '%s', '%s', %d)
	""" % [equipo_id, temporada, jornada, partido_id,
		   DatabaseManager.escape_text(tipo),
		   DatabaseManager.escape_text(descripcion),
		   cantidad])
