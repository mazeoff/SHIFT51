class_name ShiftPlayer
extends CharacterBody3D

const SPEED := 4.5
const MOUSE_SENSITIVITY := 0.0025
const RAY_DISTANCE := 3.5
var peer_id: int
var is_local := false
var look_pitch := 0.0
var camera: Camera3D
var current_target := ""

func configure(id: int, local_player: bool) -> void:
	peer_id = id
	is_local = local_player
	name = "Player_%d" % id
	set_multiplayer_authority(id)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.8
	visual.mesh = mesh
	visual.position.y = 0.9
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.from_hsv(fmod(float(id) * 0.19, 1.0), 0.55, 0.8)
	visual.material_override = material
	add_child(visual)
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 1.55, 0.0)
	camera.fov = 75.0
	add_child(camera)
	if is_local:
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
	_update_target()
	if Input.is_action_just_pressed("interact") and not current_target.is_empty():
		get_parent().request_interaction(peer_id, current_target)
	if Input.is_action_just_pressed("verify"):
		get_parent().request_verification(peer_id)

func _update_target() -> void:
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_transform.basis.z * RAY_DISTANCE)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	current_target = ""
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if collider != null and collider.has_meta("interaction_id"):
			current_target = str(collider.get_meta("interaction_id"))
	get_parent().update_interaction_prompt(current_target, get_parent().container_carrier == peer_id)

@rpc("any_peer", "call_remote", "unreliable", 1)
func _sync_transform(remote_position: Vector3, remote_yaw: float) -> void:
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	global_position = remote_position
	rotation.y = remote_yaw
	if multiplayer.is_server():
		get_parent().relay_player_transform(peer_id, remote_position, remote_yaw)
