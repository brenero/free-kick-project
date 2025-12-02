extends MeshInstance3D

@export var radius: float = 0.5
@export var segments: int = 32
@export var circle_color: Color = Color(1.0, 1.0, 1.0, 0.5)

var immediate_mesh: ImmediateMesh

func _ready() -> void:
	immediate_mesh = ImmediateMesh.new()
	mesh = immediate_mesh

	# Desenhar círculo primeiro para criar a surface
	draw_circle()

	# Criar material semi-transparente DEPOIS de desenhar
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = circle_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	set_surface_override_material(0, material)

func draw_circle():
	immediate_mesh.clear_surfaces()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	# Desenhar círculo com múltiplos segmentos
	for i in range(segments + 1):
		var angle = (float(i) / float(segments)) * TAU
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		immediate_mesh.surface_add_vertex(Vector3(x, y, 0))

	immediate_mesh.surface_end()

func set_radius(new_radius: float):
	radius = new_radius
	draw_circle()

func set_color(new_color: Color):
	circle_color = new_color
	var material = get_surface_override_material(0)
	if material:
		material.albedo_color = new_color

func set_active(active: bool):
	if active:
		set_color(Color(0, 1, 0, 0.5))  # Verde quando ativo
	else:
		set_color(Color(1, 1, 1, 0.5))  # Branco quando inativo
