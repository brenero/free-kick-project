extends CanvasLayer

var score = 0
var label: Label

func _ready():
	create_score_label()
	update_display()

func create_score_label():
	# Criar Label para o score
	label = Label.new()
	label.name = "ScoreLabel"

	# Configurar fonte e tamanho
	label.add_theme_font_size_override("font_size", 32)

	# Posicionar no canto superior direito
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.position = Vector2(-150, 20)
	label.size = Vector2(140, 50)

	# Estilizar
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 4)

	add_child(label)

func increment_score():
	score += 1
	update_display()

	# Animação de feedback
	if label:
		var tween = create_tween()
		tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.15)
		tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)

func update_display():
	if label:
		label.text = "Gols: %d" % score

func reset_score():
	score = 0
	update_display()
