class_name EnergyMoralService
extends RefCounted

## Aplica los efectos de un partido sobre energía y moral de un jugador.
## resultado: "victoria", "empate", "derrota"
static func apply_match_effects(jugador_id: int, minutos: int, resultado: String, fue_titular: bool) -> bool:
	var delta_energia = -int(float(minutos) * CareerConfig.ENERGIA_POR_MIN)
	var delta_moral = 0

	match resultado:
		"victoria": delta_moral += CareerConfig.MORAL_VICTORIA
		"empate":   delta_moral += CareerConfig.MORAL_EMPATE
		"derrota":  delta_moral += CareerConfig.MORAL_DERROTA

	if fue_titular:
		delta_moral += CareerConfig.MORAL_TITULAR

	return DatabaseManager.execute("""
		UPDATE jugadores SET
			energia = MAX(%d, MIN(%d, COALESCE(energia, 80) + (%d))),
			moral   = MAX(%d, MIN(%d, COALESCE(moral,   70) + (%d)))
		WHERE id = %d
	""" % [CareerConfig.ENERGIA_MIN, CareerConfig.ENERGIA_MAX, delta_energia,
		   CareerConfig.MORAL_MIN,   CareerConfig.MORAL_MAX,   delta_moral,
		   jugador_id])

## Aplica la penalización de moral a un jugador no convocado.
static func apply_no_convocado(jugador_id: int) -> bool:
	return DatabaseManager.execute("""
		UPDATE jugadores SET
			moral = MAX(%d, MIN(%d, COALESCE(moral, 70) + (%d)))
		WHERE id = %d
	""" % [CareerConfig.MORAL_MIN, CareerConfig.MORAL_MAX,
		   CareerConfig.MORAL_NO_CONVOCADO, jugador_id])

## Aplica la recuperación de energía y decadencia de moral al avanzar jornada.
## jugadores_que_jugaron: Array[int] de IDs de jugadores que estuvieron en el partido.
static func recover_jornada(equipo_id: int, jugadores_que_jugaron: Array) -> bool:
	if jugadores_que_jugaron.is_empty():
		# Jornada de descanso — todos recuperan el máximo
		return DatabaseManager.execute("""
			UPDATE jugadores SET
				energia = MIN(%d, COALESCE(energia, 80) + %d)
			WHERE equipo_id = %d
		""" % [CareerConfig.ENERGIA_MAX, CareerConfig.ENERGIA_RECUPERACION_DESCANSO, equipo_id])

	var ids_str = ", ".join(jugadores_que_jugaron.map(func(id): return str(id)))
	var s = true

	# Los que jugaron: recuperación reducida (ya perdieron energía vía apply_match_effects)
	s = s and DatabaseManager.execute("""
		UPDATE jugadores SET
			energia = MIN(%d, COALESCE(energia, 80) + %d)
		WHERE equipo_id = %d AND id IN (%s)
	""" % [CareerConfig.ENERGIA_MAX, CareerConfig.ENERGIA_RECUPERACION_JORNADA, equipo_id, ids_str])

	# Los que NO jugaron: recuperación plena, pero penalización de moral
	s = s and DatabaseManager.execute("""
		UPDATE jugadores SET
			energia = MIN(%d, COALESCE(energia, 80) + %d),
			moral   = MAX(%d, MIN(%d, COALESCE(moral, 70) + (%d)))
		WHERE equipo_id = %d AND id NOT IN (%s)
	""" % [CareerConfig.ENERGIA_MAX, CareerConfig.ENERGIA_RECUPERACION_SUPLENTE,
		   CareerConfig.MORAL_MIN, CareerConfig.MORAL_MAX, CareerConfig.MORAL_NO_CONVOCADO,
		   equipo_id, ids_str])

	return s

## Devuelve el factor de rendimiento (0.88–1.08) según energía y moral actuales.
static func get_rendimiento_factor(jugador: Dictionary) -> float:
	var factor := 1.0
	var moral   := int(jugador.get("moral",   CareerConfig.MORAL_INICIAL))
	var energia := int(jugador.get("energia", CareerConfig.ENERGIA_INICIAL))

	if moral >= 80:
		factor *= CareerConfig.BONUS_MORAL_ALTO
	elif moral <= 30:
		factor *= CareerConfig.PENALIZACION_MORAL_BAJO

	if energia <= CareerConfig.ENERGIA_UMBRAL_BAJO:
		factor *= CareerConfig.PENALIZACION_ENERGIA_BAJA

	return factor
