extends Control

@onready var lbl_status = $Margin/VBox/Status
@onready var btn_validar = $Margin/VBox/Grid/BtnValidar
@onready var btn_reparar = $Margin/VBox/Grid/BtnReparar
@onready var btn_salir = $Margin/VBox/BtnSalir

func _ready() -> void:
	btn_validar.pressed.connect(_on_validar)
	btn_reparar.pressed.connect(_on_reparar)
	btn_salir.pressed.connect(_on_salir)
	
	if not DatabaseManager.is_ready():
		lbl_status.text = "Conectando DB..."
		DatabaseManager.connect_to_db("res://datos/PRUEBA.db")
	lbl_status.text = "Listo para ejecutar herramientas DB."

func _on_validar() -> void:
	lbl_status.text = "Validando..."
	await get_tree().process_frame
	var reporte = DatabaseValidator.validate_database()
	if reporte["status"] == "VALID":
		if reporte["warnings"].is_empty():
			lbl_status.text = "Validacion OK. Sin warnings."
		else:
			lbl_status.text = "Validacion OK. Warnings:\n" + "\n".join(reporte["warnings"])
	else:
		lbl_status.text = "Validacion FALLIDA.\nErrores:\n" + "\n".join(reporte["errors"])
		
func _on_reparar() -> void:
	lbl_status.text = "Reparando clasificaciones..."
	await get_tree().process_frame
	var res = ClasificacionReparador.reparar_clasificacion_actual()
	if res["errores"].is_empty():
		lbl_status.text = "Reparacion completada.\nCreadas: %d\nEliminadas: %d" % [res["filas_creadas"], res["filas_eliminadas"]]
	else:
		lbl_status.text = "Error en reparacion:\n" + "\n".join(res["errores"])

func _on_salir() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/menu_principal.tscn")
