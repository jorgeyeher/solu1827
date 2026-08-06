class_name CareerConfig
extends RefCounted

# =============================================================
# ENERGÍA — Todas las constantes son configurables aquí
# =============================================================
const ENERGIA_MAX        := 100
const ENERGIA_MIN        := 0
const ENERGIA_INICIAL    := 80
const ENERGIA_POR_MIN    := 0.278   # Desgaste por minuto jugado (25 pts por 90 min)
const ENERGIA_RECUPERACION_JORNADA  := 20   # Recuperación por jornada (jugador que jugó)
const ENERGIA_RECUPERACION_SUPLENTE := 28   # Jugador que no jugó pero fue convocado
const ENERGIA_RECUPERACION_DESCANSO := 35   # Jornada sin partido (bye week)
const ENERGIA_UMBRAL_BAJO := 30     # Por debajo de este valor aplica penalización

# =============================================================
# MORAL
# =============================================================
const MORAL_MAX          := 100
const MORAL_MIN          := 0
const MORAL_INICIAL      := 70
const MORAL_VICTORIA     := 4
const MORAL_EMPATE       := 1
const MORAL_DERROTA      := -4
const MORAL_TITULAR      := 1       # Bonus por jugar de titular
const MORAL_NO_CONVOCADO := -1      # Por no entrar en la convocatoria
const MORAL_DECADENCIA   := -1      # Decadencia pasiva por jornada sin jugar

# =============================================================
# MODIFICADORES DE RENDIMIENTO (% sobre cálculo de poder)
# =============================================================
const BONUS_MORAL_ALTO          := 1.08   # moral >= 80
const PENALIZACION_MORAL_BAJO   := 0.92   # moral <= 30
const PENALIZACION_ENERGIA_BAJA := 0.88   # energia <= ENERGIA_UMBRAL_BAJO

# =============================================================
# FINANZAS
# =============================================================
const INGRESO_LOCAL_BASE         := 10000   # Taquilla partido como local
const PREMIO_VICTORIA            := 5000
const PREMIO_EMPATE              := 2000
const PREMIO_DERROTA             := 0
const COSTO_OPERATIVO_JORNADA    := 3000    # Gastos fijos por jornada
const PRESUPUESTO_INICIAL        := 500000
const PRESUPUESTO_SALARIAL_INIC  := 200000

# =============================================================
# VERSIÓN DE GUARDADO
# =============================================================
const SAVE_VERSION := 2
