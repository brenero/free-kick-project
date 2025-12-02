extends CanvasLayer

var label: Label
var last_error: float = 0.0
var last_radius: float = 0.0
var last_power: float = 0.0
var last_overshoot: bool = false

func _ready():
	create_debug_label()

func create_debug_label():
	label = Label.new()
	label.name = "DebugLabel"

	# Configurar fonte
	label.add_theme_font_size_override("font_size", 18)

	# Posicionar no canto inferior esquerdo
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.position = Vector2(20, -120)
	label.size = Vector2(300, 100)

	# Estilizar
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 2)

	add_child(label)
	update_display()

func update_info(error: float, radius: float, power: float, overshoot: bool):
	last_error = error
	last_radius = radius
	last_power = power
	last_overshoot = overshoot
	update_display()

func update_display():
	if label:
		label.text = "DEBUG INFO:\n"
		label.text += "Error: %.1f%%\n" % last_error
		label.text += "Radius: %.2fm\n" % last_radius
		label.text += "Power: %.1fn\n" % last_power
		label.text += "Overshoot: %s" % ("YES" if last_overshoot else "NO")
