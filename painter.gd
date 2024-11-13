extends Node3D

@export var paintable_group: String = "paintable"

var _try_paint: bool = false
var _mesh_instances: Array[MeshInstance3D]
var _mesh_data_tools: Array[MeshDataTool]
var _images: Array[Image]

class FaceHit:
	var mesh_index: int
	var global_point: Vector3
	var global_vertex_positions: Array[Vector3]
	var uvs: Array[Vector2]
	var camera_distance_squared: float

func _ready() -> void:
	assert(paintable_group)
	var nodes = get_tree().get_nodes_in_group(paintable_group)
	for node in nodes:
		var mesh_instances = _find_meshes(node)
		for mesh_instance in mesh_instances:
			_setup_paintable_mesh(mesh_instance)

func _find_meshes(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in node.get_children():
		meshes.append_array(_find_meshes(child))

	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)

	return meshes

func _setup_paintable_mesh(mesh_instance: MeshInstance3D):
	var index = _mesh_instances.size()

	var array_mesh: ArrayMesh
	if mesh_instance.mesh is ArrayMesh:
		array_mesh = mesh_instance.mesh
	else:
		array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_instance.mesh.get_mesh_arrays())

	var mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(array_mesh, 0)

	var image_size = Vector2(60 * mesh_instance.scale.x, 60 * mesh_instance.scale.y)
	var image = Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)

	var overlay_material = StandardMaterial3D.new()
	overlay_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mesh_instance.material_overlay = overlay_material

	_mesh_instances.push_back(mesh_instance)
	_mesh_data_tools.push_back(mesh_data_tool)
	_images.push_back(image)

	_update_mesh_texture(index)

func _update_mesh_texture(index: int) -> void:
	var mesh_instance = _mesh_instances[index]
	var image = _images[index]
	var material = mesh_instance.material_overlay as BaseMaterial3D
	material.albedo_texture = ImageTexture.create_from_image(image)

func _unhandled_input(event: InputEvent) -> void:
	var mouse_button_event := event as InputEventMouseButton
	if mouse_button_event:
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			_try_paint = true

	var mouse_motion_event := event as InputEventMouseMotion
	if mouse_motion_event:
		if mouse_motion_event.button_mask & MOUSE_BUTTON_LEFT:
			_try_paint = true

func _physics_process(delta: float) -> void:
	if !_try_paint:
		return
	_try_paint = false

	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var ray_length = 1000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length

	var face_hit: FaceHit = null

	for mesh_index in range(0, _mesh_instances.size()):
		var mesh_instance = _mesh_instances[mesh_index]
		var mesh_data = _mesh_data_tools[mesh_index]

		for face in range(0, mesh_data.get_face_count()):
			var v1_index = mesh_data.get_face_vertex(face, 0)
			var v2_index = mesh_data.get_face_vertex(face, 1)
			var v3_index = mesh_data.get_face_vertex(face, 2)

			var v1 = mesh_instance.global_transform * mesh_data.get_vertex(v1_index)
			var v2 = mesh_instance.global_transform * mesh_data.get_vertex(v2_index)
			var v3 = mesh_instance.global_transform * mesh_data.get_vertex(v3_index)

			var point = Geometry3D.ray_intersects_triangle(
				from, to, v1, v2, v3
			)

			if point == null:
				continue

			if face_hit == null || from.distance_squared_to(point) < face_hit.camera_distance_squared:
				face_hit = FaceHit.new()
				face_hit.mesh_index = mesh_index
				face_hit.camera_distance_squared = from.distance_squared_to(point)
				face_hit.global_point = point
				face_hit.global_vertex_positions = [v1, v2, v3]
				face_hit.uvs = [
					mesh_data.get_vertex_uv(v1_index),
					mesh_data.get_vertex_uv(v2_index),
					mesh_data.get_vertex_uv(v3_index)
				]

	if face_hit == null:
		return

	var barycentric = Geometry3D.get_triangle_barycentric_coords(
		face_hit.global_point,
		face_hit.global_vertex_positions[0],
		face_hit.global_vertex_positions[1],
		face_hit.global_vertex_positions[2]
	)
	
	var uv = face_hit.uvs[0] * barycentric.x \
		 + face_hit.uvs[1] * barycentric.y \
		 + face_hit.uvs[2] * barycentric.z
		
	var image = _images[face_hit.mesh_index]
	var image_size = image.get_size()
	var pixel = Vector2i(roundf(uv.x * image_size.x - 0.5), roundf(uv.y * image_size.y - 0.5))
	#image.set_pixelv(pixel, Color.RED)
	image.fill_rect(Rect2i(pixel.x - 1, pixel.y - 1, 2, 2), Color.RED)

	_update_mesh_texture(face_hit.mesh_index)
