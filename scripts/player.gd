class_name ShiftPlayer
extends CharacterBody3D

const SPEED := 4.5
const MOUSE_SENSITIVITY := 0.0025

var peer_id: int
var is_local := false
var look_pitch := 0.0
var camera: Camera3D

func configure(id: int, local_player: bool) -> void:
	peer_id = id
	is_local = local_player
	name = "Player_%d" % id
	set_multiplayer_authority(id)
	_build_body()
	if is_local:
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	mesh_instance.mesh = capsule
	mesh_instance.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.from_hsv(fmod(float(peer_id) * 0.19, 1.0), 0.55, 0.8)
	mesh_instance.material_override = material
	add_child(mesh_instance)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 1.55, 0.0)
	camera.fov = 75.0
	add_child(camera)

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		look_pitch = clamp(look_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.45, 1.45)
		camera.rotation.x = look_pitch
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_local:
		return
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()
	_sync_transform.rpc(global_position, rotation.y)
	if Input.is_action_just_pressed("interact"):
		get_parent().request_door_interaction(peer_id, global_position)
	if Input.is_action_just_pressed("verify"):
		get_parent().request_verification(peer_id, global_position)

@rpc("any_peer", "call_remote", "unreliable", 1)
func _sync_transform(remote_position: Vector3, remote_yaw: float) -> void:
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	global_position = remote_position
	rotation.y = remote_yaw
	if multiplayer.is_server():
		get_parent().relay_player_transform(peer_id, remote_position, remote_yaw)
