extends Node3D

signal goal_scored

var goal_counted = false
var goal_area: Area3D

func _ready():
	create_goal_detection_area()

func create_goal_detection_area():
	# Criar Area3D para detecção
	goal_area = Area3D.new()
	goal_area.name = "GoalDetectionArea"

	# Criar collision shape (caixa cobrindo área interna do gol)
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()

	# Dimensões FIFA: largura 7.32m, altura 2.44m, profundidade 1m
	box_shape.size = Vector3(7.32, 2.44, 1.0)
	collision_shape.shape = box_shape

	# Posicionar logo atrás da linha do gol
	collision_shape.position = Vector3(0, 1.22, 0.5)  # Y = metade da altura

	goal_area.add_child(collision_shape)
	add_child(goal_area)

	# Configurar collision layers
	goal_area.collision_layer = 2  # Layer 2 para goal detection
	goal_area.collision_mask = 1   # Mask 1 para detectar bola

	# Conectar sinal
	goal_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	# Verificar se é a bola e se gol ainda não foi contado
	if (body.name == "Ball" or body.is_in_group("ball")) and not goal_counted:
		goal_counted = true
		goal_scored.emit()
		print("⚽ GOL DETECTADO!")

func reset():
	goal_counted = false
