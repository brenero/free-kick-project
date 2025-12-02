extends CanvasLayer

# Timing bar variables
var cursor_position: float = 0.0
var charging: bool = false

# References
@onready var bar_container: Control = $Control
@onready var background: ColorRect = $Control/Background
@onready var perfect_zone: ColorRect = $Control/PerfectZone
@onready var ok_zone: ColorRect = $Control/OkZone
@onready var overshoot_zone: ColorRect = $Control/OvershootZone
@onready var cursor: ColorRect = $Control/Cursor

# Bar dimensions
const BAR_WIDTH = 400
const BAR_HEIGHT = 40

func _ready() -> void:
	create_timing_bar_ui()
	hide()

func create_timing_bar_ui():
	# Container principal
	bar_container = Control.new()
	bar_container.name = "Control"
	bar_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar_container.offset_left = -BAR_WIDTH / 2.0
	bar_container.offset_top = -80.0
	bar_container.offset_right = BAR_WIDTH / 2.0
	bar_container.offset_bottom = -80.0 + BAR_HEIGHT
	add_child(bar_container)

	# Background (fundo escuro)
	background = ColorRect.new()
	background.name = "Background"
	background.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	background.color = Color(0.1, 0.1, 0.1, 0.8)
	bar_container.add_child(background)

	# Zona perfeita (0-70% = verde)
	perfect_zone = ColorRect.new()
	perfect_zone.name = "PerfectZone"
	perfect_zone.size = Vector2(BAR_WIDTH * 0.70, BAR_HEIGHT)
	perfect_zone.color = Color(0.0, 0.8, 0.0, 0.6)  # Verde
	bar_container.add_child(perfect_zone)

	# Zona OK (70-90% = amarelo)
	ok_zone = ColorRect.new()
	ok_zone.name = "OkZone"
	ok_zone.position = Vector2(BAR_WIDTH * 0.70, 0)
	ok_zone.size = Vector2(BAR_WIDTH * 0.20, BAR_HEIGHT)
	ok_zone.color = Color(0.9, 0.9, 0.0, 0.6)  # Amarelo
	bar_container.add_child(ok_zone)

	# Zona overshoot (90-100% = vermelho)
	overshoot_zone = ColorRect.new()
	overshoot_zone.name = "OvershootZone"
	overshoot_zone.position = Vector2(BAR_WIDTH * 0.90, 0)
	overshoot_zone.size = Vector2(BAR_WIDTH * 0.10, BAR_HEIGHT)
	overshoot_zone.color = Color(1.0, 0.0, 0.0, 0.7)  # Vermelho
	bar_container.add_child(overshoot_zone)

	# Cursor (linha branca vertical)
	cursor = ColorRect.new()
	cursor.name = "Cursor"
	cursor.size = Vector2(4, BAR_HEIGHT)
	cursor.color = Color(1.0, 1.0, 1.0, 1.0)  # Branco sólido
	cursor.position = Vector2(0, 0)
	bar_container.add_child(cursor)

func _process(_delta: float) -> void:
	if charging:
		update_cursor_visual()

func start_charge(_max_charge_time: float):
	charging = true
	cursor_position = 0.0
	show()

func update_charge(normalized_charge: float):
	cursor_position = clamp(normalized_charge, 0.0, 1.0)

func stop_charge():
	charging = false
	hide()

func get_cursor_position() -> float:
	return cursor_position

func update_cursor_visual():
	if cursor:
		cursor.position.x = cursor_position * BAR_WIDTH - 2  # -2 para centralizar a linha de 4px

func calculate_error_percentage(cursor_pos: float) -> float:
	if cursor_pos >= 0.90:  # Overshoot zone
		return 100.0
	elif cursor_pos >= 0.70:  # OK zone
		return lerp(30.0, 70.0, (cursor_pos - 0.70) / 0.20)
	else:  # Perfect zone
		return lerp(0.0, 30.0, cursor_pos / 0.70)
