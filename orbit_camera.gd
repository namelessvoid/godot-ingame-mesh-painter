extends Node3D

@export var zoom := 1.0:
	get: return zoom
	set(value):
		zoom = clampf(value, 1.0, 50.0)

@export var elevation := -45.0:
	get: return elevation
	set(value):
		elevation = clampf(value, -80, -10)

@export var translation_speed := 5.0
@export var rotation_speed := 0.25

@onready var _elevation_node := $ElevationNode as Node3D
@onready var _camera := $ElevationNode/Camera3D as Camera3D

var _translation := Vector2.ZERO

func focus_on(p_focus: Node3D) -> void:
	global_transform.origin = p_focus.global_transform.origin

func make_current() -> void:
	_camera.make_current()

func _ready() -> void:
	_camera.transform.origin.z = zoom

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("scroll_up"):
		zoom -= 1
		get_viewport().set_input_as_handled()

	if event.is_action("scroll_down"):
		zoom += 1
		get_viewport().set_input_as_handled()

	_camera.transform.origin = Vector3.ZERO
	_camera.translate_object_local(Vector3(0, 0, zoom))

	_translation = Input.get_vector("move_left", "move_right", "move_forward", "move_back") 

	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion != null && mouse_motion.button_mask & MOUSE_BUTTON_RIGHT:
		var relative_rotation := Vector2(mouse_motion.relative.y, mouse_motion.relative.x) * rotation_speed
		elevation += relative_rotation.x

		rotation_degrees.y -= relative_rotation.y

func _process(p_delta: float) -> void:
	translate_object_local(Vector3(_translation.x, 0, _translation.y) * translation_speed * p_delta * _camera.position.z)
	_elevation_node.rotation_degrees.x = elevation
