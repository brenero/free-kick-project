extends CanvasLayer

var label: Label

func _ready():
	create_instructions_label()

func create_instructions_label():
	label = Label.new()
	label.name = "InstructionsLabel"

	# Configurar fonte
	label.add_theme_font_size_override("font_size", 20)

	# Posicionar no canto superior esquerdo
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = Vector2(20, 20)
	label.size = Vector2(400, 150)

	# Estilizar
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 3)

	# Texto com instruções
	label.text = """CONTROLES:
WASD - Mirar
ESPAÇO - Segurar para carregar, soltar para chutar
R - Resetar bola

OBJETIVO:
Faça gols acertando o timing perfeito!
Zona verde = preciso
Zona vermelha = overshoot (penalidade)"""

	add_child(label)
