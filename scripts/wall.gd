extends Node3D

# Parâmetros da barreira
@export var num_players: int = 5  # Número de jogadores na barreira
@export var player_spacing: float = 0.7  # Espaçamento entre jogadores
@export var player_height: float = 1.8  # Altura dos jogadores (em metros)
@export var wall_distance: float = 9.15  # Distância da bola (9.15m = regulamento FIFA)
@export var jump_chance: float = 0.6  # Chance dos jogadores pularem (0.0 a 1.0)
@export var jump_delay: float = 0.4  # Delay antes de pular após o chute
@export var jump_height: float = 0.8  # Altura do pulo

# Referências
var players: Array[Node3D] = []
var ball: RigidBody3D = null
var ball_initial_pos: Vector3
var has_jumped: bool = false
var jump_timer: float = 0.0
var is_tracking: bool = false

func _ready() -> void:
	create_wall_players()
	call_deferred("find_ball")

func _process(delta: float) -> void:
	if not ball:
		return

	# Detectar quando a bola é chutada
	if not is_tracking and ball.linear_velocity.length() > 1.0:
		is_tracking = true
		has_jumped = false
		jump_timer = 0.0

	# Timer para pulo da barreira
	if is_tracking and not has_jumped:
		jump_timer += delta
		if jump_timer >= jump_delay:
			attempt_jump()
			has_jumped = true

	# Resetar quando a bola para
	if is_tracking and ball.linear_velocity.length() < 0.5:
		reset_wall()

func create_wall_players() -> void:
	# Calcular largura total da barreira
	var total_width = (num_players - 1) * player_spacing

	# Criar jogadores centralizados
	for i in range(num_players):
		var player = create_player()
		var offset_x = -total_width / 2.0 + i * player_spacing
		player.position = Vector3(offset_x, 0, 0)
		add_child(player)
		players.append(player)

func create_player() -> Node3D:
	# Criar um jogador simples usando formas CSG
	var player = Node3D.new()

	# Calcular proporções baseadas na altura configurada
	# Altura padrão é 1.8m (corpo 1.6m + cabeça 0.2m)
	var scale_factor = player_height / 1.8
	var body_height = 1.6 * scale_factor
	var head_radius = 0.18 * scale_factor
	var body_radius = 0.25 * scale_factor

	# Corpo (cilindro)
	var body = CSGCylinder3D.new()
	body.radius = body_radius
	body.height = body_height
	body.sides = 8
	player.add_child(body)
	body.position = Vector3(0, body_height / 2.0, 0)

	# Cabeça (esfera)
	var head = CSGSphere3D.new()
	head.radius = head_radius
	head.radial_segments = 8
	head.rings = 8
	player.add_child(head)
	head.position = Vector3(0, body_height + head_radius, 0)

	# Adicionar StaticBody3D para colisão
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(body_radius * 2.0, player_height, body_radius * 1.6)
	collision_shape.shape = shape
	collision_shape.position = Vector3(0, player_height / 2.0, 0)

	static_body.add_child(collision_shape)
	player.add_child(static_body)

	return player

func attempt_jump() -> void:
	# Cada jogador decide individualmente se pula
	for player in players:
		if randf() < jump_chance:
			jump_player(player)

func jump_player(player: Node3D) -> void:
	# Animar pulo do jogador
	var tween = create_tween()
	tween.set_parallel(true)

	# Subir
	tween.tween_property(player, "position:y", jump_height, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Descer
	tween.tween_property(player, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.3)

func reset_wall() -> void:
	# Resetar estado da barreira
	is_tracking = false
	has_jumped = false
	jump_timer = 0.0

	# Resetar posições dos jogadores
	for player in players:
		player.position.y = 0.0

func find_ball() -> void:
	# Procurar a bola na cena
	var root = get_tree().root
	ball = find_node_recursive(root, "Ball") as RigidBody3D

	if ball:
		ball_initial_pos = ball.global_position

func find_node_recursive(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var result = find_node_recursive(child, node_name)
		if result:
			return result
	return null

func position_wall_at_distance(ball_pos: Vector3, goal_pos: Vector3) -> void:
	# Posicionar barreira a uma distância específica da bola em direção ao gol
	var direction = (goal_pos - ball_pos).normalized()
	global_position = ball_pos + direction * wall_distance
	global_position.y = 0  # Manter no chão

	# Rotacionar para ficar de frente para a bola
	look_at(ball_pos, Vector3.UP)

func position_wall_intelligently(ball_pos: Vector3, goal_pos: Vector3, side: int) -> void:
	"""
	Posiciona barreira com deslocamento lateral inteligente

	Args:
		ball_pos: Posição da bola
		goal_pos: Posição do gol
		side: -1 (esquerda) ou 1 (direita)
	"""
	# Posição base (9.15m da bola em direção ao gol)
	var direction = (goal_pos - ball_pos).normalized()
	global_position = ball_pos + direction * wall_distance
	global_position.y = 0  # Manter no chão

	# Deslocamento lateral baseado no lado
	var lateral_offset = side * 1.5  # 1.5m de deslocamento lateral
	global_position.x += lateral_offset

	# Rotacionar para ficar de frente para a bola
	look_at(ball_pos, Vector3.UP)
