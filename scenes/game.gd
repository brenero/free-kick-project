extends Node3D

# Kick charging variables
var charging: bool = false
@export var charge_time: float = 0.0
@export var MAX_CHARGE_TIME: float = 2.0  # Tempo máximo para carregar (ex: 2 segundos)
@export var MAX_KICK_POWER: float = 20.0 # Força máxima base do chute
@export var SHOT_MULTIPLIER: float = 1.0 # Multiplicador de força para balanceamento

# Aiming system variables
var aim_position: Vector2 = Vector2(0.5, 0.5)  # Coordenadas UV no gol (0-1)
@export var AIM_SPEED: float = 0.5  # Velocidade de movimento da mira
@export var precision_radius: float = 0.5  # Raio do círculo de erro (modificado por cartas no futuro)

# Goal dimensions and position
const GOAL_WIDTH = 7.32  # Largura FIFA
const GOAL_HEIGHT = 2.44  # Altura FIFA
const GOAL_Z = 52.5  # Posição z do gol na linha de fundo FIFA
const GOALKEEPER_Z = 52.5  # Goleiro posicionado na linha do gol

# Ball spawn constraints (FIFA dimensions)
const PENALTY_AREA_DEPTH = 16.5  # Grande área: 16.5m de profundidade
const PENALTY_AREA_FRONT = 36.0  # Entrada da grande área: 52.5 - 16.5
const SHOOT_AREA_WIDTH = 10.0  # Largura da área de chute
const SHOOT_AREA_DEPTH = 10.0  # Profundidade da área de chute (10m à frente da grande área)
const SHOOT_AREA_FRONT = 26.0  # Início da área de chute: 36.0 - 10.0
const FIELD_WIDTH = 68.0  # Largura do campo FIFA (para validações)
const FIELD_DEPTH = 105.0  # Profundidade do campo FIFA (para validações)
const CENTER_THRESHOLD = 1.0  # Threshold para considerar bola "no centro"

# Visual field line constants (FIFA official dimensions)
const FIELD_LINE_WIDTH = 68.0            # Largura oficial FIFA
const FIELD_LINE_LENGTH = 105.0          # Comprimento oficial FIFA (campo completo)
const VISUAL_PENALTY_AREA_WIDTH = 40.32  # Largura da grande área FIFA
const VISUAL_PENALTY_AREA_DEPTH = 16.5   # Profundidade da grande área FIFA
const VISUAL_GOAL_AREA_WIDTH = 18.32     # Largura da pequena área FIFA
const VISUAL_GOAL_AREA_DEPTH = 5.5       # Profundidade da pequena área FIFA
const LINE_WIDTH = 0.12                  # Largura das linhas: 12cm FIFA standard

# References
var initial_ball_transform: Transform3D
@onready var ball: RigidBody3D = $Ball
@onready var goalkeeper: CharacterBody3D = $Goalkeeper
@onready var wall: Node3D = $Wall
@onready var camera: Camera3D = $Camera3D
var aim_marker: MeshInstance3D  # Marcador visual da mira
var precision_circle: MeshInstance3D  # Círculo de precisão
var timing_bar: CanvasLayer  # UI da barra de timing
var goal_detector: Node3D  # Detector de gol
var score_hud: CanvasLayer  # HUD de pontuação
var debug_hud: CanvasLayer  # HUD de debug
var instructions_hud: CanvasLayer  # HUD de instruções

# Control flags
var goal_reset_timer_active: bool = false


func _ready() -> void:
	# 1. Gerar posição inicial aleatória da bola
	var new_ball_pos = generate_random_ball_position()
	ball.global_position = new_ball_pos
	initial_ball_transform = ball.global_transform

	# 2. Criar elementos UI e jogo
	create_aim_marker()
	create_precision_circle()
	create_timing_bar()
	create_goal_detector()
	create_score_hud()
	create_debug_hud()
	create_instructions_hud()
	update_aim_marker_position()

	# 3. Posicionar defesa e câmera inteligentemente (após criar elementos)
	await get_tree().process_frame
	setup_defense_positioning(ball.global_position)
	setup_camera_position(ball.global_position)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("retry"):
		reset_ball()

	# Controle de mira com WASD
	if Input.is_action_pressed("aim_right"):
		aim_position.x -= AIM_SPEED * delta
	if Input.is_action_pressed("aim_left"):
		aim_position.x += AIM_SPEED * delta
	if Input.is_action_pressed("aim_up"):
		aim_position.y += AIM_SPEED * delta
	if Input.is_action_pressed("aim_down"):
		aim_position.y -= AIM_SPEED * delta

	# Clampar valores entre 0 e 1 para não sair do gol
	aim_position.x = clamp(aim_position.x, 0.0, 1.0)
	aim_position.y = clamp(aim_position.y, 0.0, 1.0)

	# Atualizar posição visual do marcador
	update_aim_marker_position()

	if Input.is_action_pressed("kick"):
		if not charging:
			charging = true
			charge_time = 0.0
			if timing_bar and timing_bar.has_method("start_charge"):
				timing_bar.start_charge(MAX_CHARGE_TIME)

			# Ativar círculo de precisão (mudar cor para verde)
			if precision_circle and precision_circle.has_method("set_active"):
				precision_circle.set_active(true)

		if charging:
			charge_time = min(charge_time + delta, MAX_CHARGE_TIME)

			# Atualizar timing bar
			var normalized_charge = charge_time / MAX_CHARGE_TIME
			if timing_bar and timing_bar.has_method("update_charge"):
				timing_bar.update_charge(normalized_charge)

	elif Input.is_action_just_released("kick"):
		if charging:
			# Capturar posição do cursor na timing bar
			var cursor_pos = 0.0
			if timing_bar and timing_bar.has_method("get_cursor_position"):
				cursor_pos = timing_bar.get_cursor_position()

			# Calcular erro de execução baseado no timing
			var error_percentage = 0.0
			if timing_bar and timing_bar.has_method("calculate_error_percentage"):
				error_percentage = timing_bar.calculate_error_percentage(cursor_pos)

			# Fator de 0.0 a 1.0
			var normalized_charge = charge_time / MAX_CHARGE_TIME

			# Calcula a força final (baseada no tempo e multiplicada pelo seu fator de balanceamento)
			var final_kick_power = normalized_charge * MAX_KICK_POWER * SHOT_MULTIPLIER

			# Verificar overshoot e aplicar punições
			var radius = precision_radius
			var is_overshoot = error_percentage >= 90.0

			# Calcular ponto de impacto desejado e real
			var p_desired = aim_uv_to_world(aim_position)
			var p_real: Vector3

			if is_overshoot:
				# OVERSHOOT: Chute forte que vai para fora (acima do gol)
				error_percentage = 100.0
				# NÃO reduzir força - manter forte para passar longe
				# Forçar mira para bem acima do gol
				var overshoot_aim = aim_position
				overshoot_aim.y = 1.5  # Muito acima do topo do gol (150% da altura)
				p_real = aim_uv_to_world(overshoot_aim)
				# Adicionar desvio aleatório grande
				var overshoot_offset = Vector3(
					randf_range(-2.0, 2.0),  # Desvio horizontal
					randf_range(1.0, 3.0),   # Desvio para cima
					0
				)
				p_real += overshoot_offset
			else:
				# Chute normal com precisão baseada no timing
				p_real = calculate_real_impact_point(p_desired, radius, error_percentage)

			# Atualizar debug info
			if debug_hud and debug_hud.has_method("update_info"):
				debug_hud.update_info(error_percentage, radius, final_kick_power, is_overshoot)

			# Executar chute com direção calculada
			kick_ball(final_kick_power, p_real)

			# Reseta o estado
			charging = false
			charge_time = 0.0

			# Esconder timing bar
			if timing_bar and timing_bar.has_method("stop_charge"):
				timing_bar.stop_charge()

			# Desativar círculo de precisão (voltar cor branca)
			if precision_circle and precision_circle.has_method("set_active"):
				precision_circle.set_active(false)

func kick_ball(power: float, target_point: Vector3 = Vector3.ZERO):
	if ball:
		var kick_direction: Vector3

		# Se target_point foi fornecido, calcular direção para ele
		# Senão, usar direção padrão (para compatibilidade com código antigo)
		if target_point != Vector3.ZERO:
			kick_direction = (target_point - ball.global_position).normalized()
			# Garantir elevação mínima para a bola não ir reto no chão
			kick_direction.y = max(kick_direction.y, 0.2)
			kick_direction = kick_direction.normalized()
		else:
			kick_direction = Vector3(0, 0.2, 1).normalized()

		var impulse = kick_direction * power
		ball.apply_central_impulse(impulse)

func reset_ball():
	# Cancelar qualquer timer de reset automático ativo
	goal_reset_timer_active = false

	# 1. Gerar nova posição aleatória da bola
	var new_ball_pos = generate_random_ball_position()
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_position = new_ball_pos
	initial_ball_transform = ball.global_transform

	# 2. Reposicionar defesa e câmera baseado na nova posição
	setup_defense_positioning(new_ball_pos)
	setup_camera_position(new_ball_pos)

	# 3. Resets dos componentes
	if goal_detector and goal_detector.has_method("reset"):
		goal_detector.reset()

	# Reset do goleiro (após atualizar initial_position via set_initial_position)
	if goalkeeper and goalkeeper.has_method("reset"):
		goalkeeper.reset()

	# Reset da barreira
	if wall and wall.has_method("reset_wall"):
		wall.reset_wall()

# Aiming system functions
func create_aim_marker():
	# Criar esfera pequena para marcar o ponto de mira
	aim_marker = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	aim_marker.mesh = sphere_mesh

	# Material amarelo/vermelho para visibilidade
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.0)  # Amarelo
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.0)
	material.emission_energy_multiplier = 0.5
	aim_marker.set_surface_override_material(0, material)

	add_child(aim_marker)

func aim_uv_to_world(uv: Vector2) -> Vector3:
	# Mapear coordenadas UV (0-1) para posição 3D no plano do gol
	var x = (uv.x - 0.5) * GOAL_WIDTH  # Centrar horizontalmente
	var y = uv.y * GOAL_HEIGHT  # Altura do chão até o topo
	return Vector3(x, y, GOAL_Z)

func calculate_real_impact_point(p_desired: Vector3, radius: float, error_pct: float) -> Vector3:
	# Fórmula: P_real = P_desejado + (Vetor_Aleatório × R × E_%)
	# Vetor aleatório em círculo 2D (plano XY do gol)
	var angle = randf() * TAU
	var distance = randf() * radius * (error_pct / 100.0)
	var random_offset = Vector3(
		cos(angle) * distance,
		sin(angle) * distance,
		0
	)
	return p_desired + random_offset

func update_aim_marker_position():
	if aim_marker:
		aim_marker.global_position = aim_uv_to_world(aim_position)
	if precision_circle:
		precision_circle.global_position = aim_uv_to_world(aim_position)

func create_precision_circle():
	# Carregar o script do círculo de precisão
	var PrecisionCircleScript = load("res://scripts/precision_circle.gd")
	precision_circle = MeshInstance3D.new()
	precision_circle.set_script(PrecisionCircleScript)

	# Rotacionar para ficar perpendicular ao gol (encarando a câmera)
	precision_circle.rotation_degrees = Vector3(0, 180, 0)

	add_child(precision_circle)

	# Aguardar um frame para o _ready() do círculo executar
	await get_tree().process_frame

	# Configurar raio do círculo
	if precision_circle.has_method("set_radius"):
		precision_circle.set_radius(precision_radius)

	# Posicionar no ponto de mira inicial
	precision_circle.global_position = aim_uv_to_world(aim_position)

func create_timing_bar():
	# Carregar o script da timing bar
	var TimingBarScript = load("res://scripts/timing_bar.gd")
	timing_bar = CanvasLayer.new()
	timing_bar.set_script(TimingBarScript)
	add_child(timing_bar)

func create_goal_detector():
	# Carregar o script do detector de gol
	var GoalDetectorScript = load("res://scripts/goal_detector.gd")
	goal_detector = Node3D.new()
	goal_detector.name = "GoalDetector"
	goal_detector.set_script(GoalDetectorScript)

	# Posicionar no gol (mesma posição do Goal node)
	goal_detector.global_position = Vector3(0, 0, GOAL_Z)

	add_child(goal_detector)

	# Aguardar um frame e conectar sinal
	await get_tree().process_frame
	if goal_detector.has_signal("goal_scored"):
		goal_detector.goal_scored.connect(_on_goal_scored)

func create_score_hud():
	# Carregar o script do score HUD
	var ScoreHUDScript = load("res://scripts/score_hud.gd")
	score_hud = CanvasLayer.new()
	score_hud.set_script(ScoreHUDScript)
	add_child(score_hud)

func create_debug_hud():
	# Carregar o script do debug HUD
	var DebugHUDScript = load("res://scripts/debug_hud.gd")
	debug_hud = CanvasLayer.new()
	debug_hud.set_script(DebugHUDScript)
	add_child(debug_hud)

func create_instructions_hud():
	# Carregar o script das instruções
	var InstructionsHUDScript = load("res://scripts/instructions_hud.gd")
	instructions_hud = CanvasLayer.new()
	instructions_hud.set_script(InstructionsHUDScript)
	add_child(instructions_hud)

func _on_goal_scored():
	if score_hud and score_hud.has_method("increment_score"):
		score_hud.increment_score()

	print("⚽ GOOOL!")

	# Ativar flag de timer
	goal_reset_timer_active = true

	# Esperar 2 segundos e resetar (se não foi cancelado manualmente)
	await get_tree().create_timer(2.0).timeout

	# Verificar se o timer ainda está ativo (não foi cancelado por retry manual)
	if goal_reset_timer_active:
		goal_reset_timer_active = false
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.global_transform = initial_ball_transform

		if goal_detector and goal_detector.has_method("reset"):
			goal_detector.reset()

# ============================================================================
# BALL SPAWN SYSTEM
# ============================================================================

func generate_random_ball_position() -> Vector3:
	"""
	Gera posição aleatória válida para a bola seguindo regras FIFA:
	1. Dentro da área de chute (10m × 10m à frente da grande área)
	2. Fora da grande área (mínimo 16.5m do gol)
	3. Dentro de cone de 120° à frente do gol
	"""
	var max_attempts = 100

	for attempt in range(max_attempts):
		# Gerar coordenadas aleatórias dentro da área de chute
		var random_x = randf_range(-SHOOT_AREA_WIDTH/2.0, SHOOT_AREA_WIDTH/2.0)
		var random_z = randf_range(SHOOT_AREA_FRONT, PENALTY_AREA_FRONT)
		var candidate = Vector3(random_x, 0.196, random_z)

		if is_valid_ball_position(candidate):
			return candidate

	# Fallback: posição segura padrão (centro da área de chute)
	print("⚠️ Não encontrou posição válida após ", max_attempts, " tentativas. Usando fallback.")
	return Vector3(0, 0.196, 31.0)

func is_valid_ball_position(pos: Vector3) -> bool:
	"""
	Valida se posição da bola atende todos os requisitos
	"""
	# 1. Verificar se está FORA da grande área
	var penalty_area_min_z = GOAL_Z - PENALTY_AREA_DEPTH
	if pos.z > penalty_area_min_z:
		return false  # Dentro da grande área

	# 2. Verificar se está dentro do campo
	if abs(pos.x) > FIELD_WIDTH / 2.0:
		return false  # Fora da largura
	if pos.z < -FIELD_DEPTH / 2.0 or pos.z > GOAL_Z:
		return false  # Fora da profundidade

	# 3. Verificar cone de 120° (±60° do centro)
	var vec_to_goal = Vector3(0, 0, GOAL_Z) - pos
	var angle_rad = atan2(vec_to_goal.x, vec_to_goal.z)
	var angle_deg = rad_to_deg(angle_rad)

	if abs(angle_deg) > 60.0:
		return false  # Fora do cone de 120°

	return true

# ============================================================================
# INTELLIGENT DEFENSE POSITIONING
# ============================================================================

func setup_defense_positioning(ball_pos: Vector3) -> void:
	"""
	Posiciona barreira e goleiro inteligentemente baseado na posição da bola
	"""
	var positions = calculate_defense_positions(ball_pos)

	# Posicionar barreira
	if wall and wall.has_method("position_wall_intelligently"):
		wall.position_wall_intelligently(ball_pos, Vector3(0, 0, GOAL_Z), positions.wall_side)

	# Atualizar posição inicial do goleiro
	if goalkeeper and goalkeeper.has_method("set_initial_position"):
		var goalkeeper_pos = Vector3(positions.goalkeeper_x, 0, GOAL_Z)
		goalkeeper.set_initial_position(goalkeeper_pos)

func calculate_defense_positions(ball_pos: Vector3) -> Dictionary:
	"""
	Calcula lado da barreira e posição do goleiro

	IMPLEMENTAÇÃO SIMPLES: Deslocamento horizontal baseado no lado da bola
	- Barreira protege lado mais próximo
	- Goleiro cobre lado oposto com deslocamento de 2.0m

	FUTURA IMPLEMENTAÇÃO REALISTA (mais complexa):
	Calcular ângulos exatos entre bola e postes para posicionamento ótimo:
	- angle_to_near_post = atan2(near_post.x - ball.x, near_post.z - ball.z)
	- angle_to_far_post = atan2(far_post.x - ball.x, far_post.z - ball.z)
	- Barreira cobre ângulo de tiro mais direto (geralmente lado próximo)
	- Goleiro posiciona-se no ponto médio da área descoberta pela barreira
	- goalkeeper_optimal_x = calcular interseção de ângulos com linha do gol

	Esta implementação futura consideraria:
	- Geometria exata do cone de visão da bola para o gol
	- Área "coberta" pela barreira (shadow zone)
	- Posicionamento ótimo do goleiro = centro da área descoberta
	"""
	var result = {
		"wall_side": 0,      # -1 = esquerda, 1 = direita
		"goalkeeper_x": 0.0  # Posição X do goleiro
	}

	# Determinar lado baseado em posição X da bola
	if abs(ball_pos.x) < CENTER_THRESHOLD:
		# CENTRO: escolha aleatória de lados
		result.wall_side = 1 if randf() > 0.5 else -1
	elif ball_pos.x > 0:
		# Bola à DIREITA: barreira cobre direita
		result.wall_side = 1
	else:
		# Bola à ESQUERDA: barreira cobre esquerda
		result.wall_side = -1

	# Goleiro se desloca para o lado OPOSTO da barreira
	# Deslocamento de 2.0m para cobrir o ângulo restante
	result.goalkeeper_x = -result.wall_side * 2.0

	return result

# ============================================================================
# CAMERA POSITIONING SYSTEM
# ============================================================================

func setup_camera_position(ball_pos: Vector3) -> void:
	"""
	Posiciona câmera para enquadrar bola + gol
	Calcula posição ótima baseada na posição da bola
	"""
	# Calcular posição ideal
	var camera_offset_x = ball_pos.x * 0.3  # Acompanha lateralmente (30%)
	var camera_offset_z = ball_pos.z - 3.0  # 3m atrás da bola
	var camera_height = 2.5  # Altura fixa de 2.5m

	var target_position = Vector3(camera_offset_x, camera_height, camera_offset_z)

	# Usar Tween para transição suave (se não for primeira vez)
	if camera.global_position.distance_to(target_position) > 0.1:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(camera, "global_position", target_position, 0.8)
	else:
		# Primeira vez: posição instantânea
		camera.global_position = target_position

	# Câmera sempre olha para o centro do gol
	camera.look_at(Vector3(0, 1.2, GOAL_Z), Vector3.UP)
