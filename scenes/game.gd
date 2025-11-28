extends Node3D

var charging: bool = false
@export var charge_time: float = 0.0
@export var MAX_CHARGE_TIME: float = 2.0  # Tempo máximo para carregar (ex: 2 segundos)
@export var MAX_KICK_POWER: float = 20.0 # Força máxima base do chute
@export var SHOT_MULTIPLIER: float = 1.0 # Multiplicador de força para balanceamento

var initial_ball_transform: Transform3D
@onready var ball: RigidBody3D = $Ball


func _ready() -> void:
	initial_ball_transform = ball.global_transform
	

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("retry"):
		reset_ball()
	
	if Input.is_action_pressed("kick"):
		if not charging:
			charging = true
			charge_time = 0.0
		
		if charging:
			charge_time = min(charge_time + delta, MAX_CHARGE_TIME)
			# (Código para UI da barra de força)
			
	elif Input.is_action_just_released("kick"):
		if charging:
			# Fator de 0.0 a 1.0
			var normalized_charge = charge_time / MAX_CHARGE_TIME 
			
			# Calcula a força final (baseada no tempo e multiplicada pelo seu fator de balanceamento)
			var final_kick_power = normalized_charge * MAX_KICK_POWER * SHOT_MULTIPLIER
			
			kick_ball(final_kick_power)
			
			# Reseta o estado
			charging = false
			charge_time = 0.0

func kick_ball(power: float):
	if ball:
		var kick_direction = Vector3(0, 0.2, 1).normalized() 
		var impulse = kick_direction * power
		ball.apply_central_impulse(impulse)

func reset_ball():
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_transform = initial_ball_transform
	
