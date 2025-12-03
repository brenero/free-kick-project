extends CharacterBody3D

# Parâmetros do goleiro
@export var reaction_time: float = 0.3  # Tempo de reação (menor = mais difícil)
@export var dive_speed: float = 8.0  # Velocidade do mergulho
@export var max_reach: float = 3.0  # Alcance máximo do goleiro (horizontal)
@export var jump_height: float = 2.0  # Altura máxima que o goleiro alcança
@export var save_probability: float = 0.7  # Probabilidade de defesa (0.0 a 1.0)
@export var return_speed: float = 3.0  # Velocidade para voltar à posição inicial

# Dimensões do gol
const GOAL_WIDTH = 7.32
const GOAL_HEIGHT = 2.44

# Estados do goleiro
enum State { IDLE, TRACKING, DIVING, RETURNING }
var current_state: State = State.IDLE

# Posição inicial
var initial_position: Vector3
var target_position: Vector3

# Referência à bola
var ball: RigidBody3D = null
var ball_tracked: bool = false
var reaction_timer: float = 0.0

# Área de detecção
var save_area: Area3D

func _ready() -> void:
	initial_position = global_position
	target_position = initial_position

	# Criar área de defesa (colisão para detectar saves)
	create_save_area()

func _physics_process(delta: float) -> void:
	if not ball:
		find_ball()
		return

	match current_state:
		State.IDLE:
			state_idle(delta)
		State.TRACKING:
			state_tracking(delta)
		State.DIVING:
			state_diving(delta)
		State.RETURNING:
			state_returning(delta)

func state_idle(delta: float) -> void:
	# Aguardar a bola ser chutada
	if ball.linear_velocity.length() > 1.0 and not ball_tracked:
		# Bola foi chutada
		ball_tracked = true
		reaction_timer = 0.0
		current_state = State.TRACKING

func state_tracking(delta: float) -> void:
	# Tempo de reação antes de reagir
	reaction_timer += delta

	if reaction_timer >= reaction_time:
		# Prever onde a bola vai chegar
		var predicted_position = predict_ball_impact()

		if predicted_position != Vector3.ZERO:
			# Decidir se tenta defender baseado na probabilidade
			var will_attempt_save = randf() < save_probability

			if will_attempt_save:
				# Calcular se a bola está dentro do alcance
				var distance_x = abs(predicted_position.x - global_position.x)
				var distance_y = abs(predicted_position.y - global_position.y)

				if distance_x <= max_reach and distance_y <= jump_height:
					# Tentar defesa
					target_position = Vector3(
						clamp(predicted_position.x, global_position.x - max_reach, global_position.x + max_reach),
						clamp(predicted_position.y, global_position.y, global_position.y + jump_height),
						global_position.z
					)
					current_state = State.DIVING
				else:
					# Bola fora de alcance - não tenta
					pass
		else:
			# Não conseguiu prever - não reage
			pass

func state_diving(delta: float) -> void:
	# Mergulhar em direção ao ponto previsto
	var direction = (target_position - global_position).normalized()
	velocity = direction * dive_speed
	move_and_slide()

	# Verificar se chegou perto do destino ou se a bola passou
	if global_position.distance_to(target_position) < 0.3 or ball.global_position.z > global_position.z + 1.0:
		# Parar e começar a voltar
		velocity = Vector3.ZERO
		current_state = State.RETURNING

func state_returning(delta: float) -> void:
	# Voltar para posição inicial
	var direction = (initial_position - global_position).normalized()
	velocity = direction * return_speed
	move_and_slide()

	# Verificar se chegou na posição inicial
	if global_position.distance_to(initial_position) < 0.1:
		global_position = initial_position
		velocity = Vector3.ZERO
		ball_tracked = false
		current_state = State.IDLE

func predict_ball_impact() -> Vector3:
	# Previsão simples: raycasting da trajetória da bola até o plano do gol
	if ball.linear_velocity.z <= 0:
		return Vector3.ZERO  # Bola indo para trás

	var ball_pos = ball.global_position
	var ball_vel = ball.linear_velocity

	# Calcular tempo até chegar no plano do gol
	var time_to_goal = (global_position.z - ball_pos.z) / ball_vel.z

	if time_to_goal <= 0:
		return Vector3.ZERO

	# Prever posição usando física básica (com gravidade)
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var predicted_x = ball_pos.x + ball_vel.x * time_to_goal
	var predicted_y = ball_pos.y + ball_vel.y * time_to_goal - 0.5 * gravity * time_to_goal * time_to_goal
	var predicted_z = global_position.z

	return Vector3(predicted_x, predicted_y, predicted_z)

func find_ball() -> void:
	# Procurar a bola na cena
	var root = get_tree().root
	ball = find_node_recursive(root, "Ball") as RigidBody3D

func find_node_recursive(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var result = find_node_recursive(child, node_name)
		if result:
			return result
	return null

func create_save_area() -> void:
	# Criar área para detectar colisões com a bola (defesas)
	save_area = Area3D.new()
	save_area.name = "SaveArea"

	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.5, 2.0, 0.5)  # Tamanho da área de defesa
	collision_shape.shape = shape

	save_area.add_child(collision_shape)
	add_child(save_area)

	# Conectar sinal de colisão
	save_area.body_entered.connect(_on_body_entered_save_area)

func _on_body_entered_save_area(body: Node3D) -> void:
	if body.name == "Ball" and current_state == State.DIVING:
		# Goleiro tocou na bola durante o mergulho - DEFESA!
		print("🧤 DEFESA DO GOLEIRO!")

		# Redirecionar a bola (rebater)
		if body is RigidBody3D:
			var deflection = Vector3(randf_range(-5, 5), randf_range(2, 5), randf_range(-8, -5))
			body.linear_velocity = deflection

func reset() -> void:
	# Resetar estado do goleiro
	global_position = initial_position
	velocity = Vector3.ZERO
	ball_tracked = false
	current_state = State.IDLE
	reaction_timer = 0.0

func set_initial_position(new_position: Vector3) -> void:
	"""
	Define nova posição inicial do goleiro
	Permite reposicionamento dinâmico baseado na bola
	"""
	initial_position = new_position
	global_position = new_position

	# Resetar estado para evitar bugs
	velocity = Vector3.ZERO
	target_position = initial_position
	ball_tracked = false
	current_state = State.IDLE
	reaction_timer = 0.0
