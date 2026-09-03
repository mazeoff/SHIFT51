extends Node3D

const PORT := 5151
const MAX_PLAYERS := 4
const RANGE := 3.7
const DOOR_POS := Vector3(0, 1.25, -6)
const BOX_START := Vector3(0, 0.5, 0.5)
const BAY_A := Vector3(-2.15, 0.2, -3.2)
const BAY_B := Vector3(2.15, 0.2, -3.2)
const ROUND_DURATION := 300.0
const OBSERVER_BREACH_MOVES := 5
const OBSERVER_POINTS := [
	Vector3(0.0, 0.8, -1.5),
	Vector3(-2.1, 0.8, 2.0),
	Vector3(2.1, 0.8, -4.7),
	Vector3(0.0, 0.8, 3.8)
]
var players := {}
var targets := {}
var door_open := false
var verification_charges := 1
var container_carrier := 0
var container_position := BOX_START
var task_resolved := false
var containment_success := false
var power_online := true
var round_started := false
var round_finished := false
var observer_point_index := 0
var observer_unseen_time := 0.0
var observer_move_delay := 2.5
var observer_move_count := 0
var observer_breached := false
var round_time_remaining := ROUND_DURATION
var timer_sync_accumulator := 0.0
var door_body: StaticBody3D
var door_mesh: MeshInstance3D
var perception_overlay: MeshInstance3D
var container_body: StaticBody3D
var container_collision: CollisionShape3D
var lights: Array[OmniLight3D] = []
var observer_visual: MeshInstance3D
var false_observer_visual: MeshInstance3D
var lobby_panel: PanelContainer
var hud: VBoxContainer
var status_label: Label
var instruction_label: Label
var evidence_label: Label
var prompt_label: Label
var result_panel: PanelContainer
var result_label: Label
var log_label: RichTextLabel
var address_edit: LineEdit
var title_label: Label
var language_label: Label
var language_option: OptionButton
var host_button: Button
var join_button: Button
var controls_label: Label
var timer_label: Label
var restart_button: Button

func _ready() -> void:
	_build_world()
	_build_ui()
	Localization.language_changed.connect(_on_language_changed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_log(Localization.text("log_initial"))

func _physics_process(delta: float) -> void:
	if multiplayer.is_server() and container_carrier != 0 and players.has(container_carrier):
		var p: ShiftPlayer = players[container_carrier]
		container_position = p.global_position - p.global_transform.basis.z * 1.15 + Vector3.UP * 1.15
		_set_container.rpc(container_position, container_carrier)
	if multiplayer.is_server() and round_started and not round_finished:
		_update_observer(delta)
		_update_round_timer(delta)

func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101518")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8ca0a3")
	env.ambient_light_energy = 0.55
	world.environment = env
	add_child(world)
	_box("Floor", Vector3(6, .2, 18), Vector3(0, -.1, 0), Color("343b3d"), true)
	_box("Ceiling", Vector3(6, .2, 18), Vector3(0, 3.1, 0), Color("24292b"), true)
	_box("LeftWall", Vector3(.2, 3.2, 18), Vector3(-3, 1.5, 0), Color("596164"), true)
	_box("RightWall", Vector3(.2, 3.2, 18), Vector3(3, 1.5, 0), Color("596164"), true)
	_box("EndWall", Vector3(6, 3.2, .2), Vector3(0, 1.5, -9), Color("596164"), true)
	_box("StartWall", Vector3(6, 3.2, .2), Vector3(0, 1.5, 9), Color("596164"), true)
	_box("DoorFrameL", Vector3(2, 3.2, .35), Vector3(-2, 1.5, -6), Color("263033"), true)
	_box("DoorFrameR", Vector3(2, 3.2, .35), Vector3(2, 1.5, -6), Color("263033"), true)
	door_body = _target("door", "Door", Vector3(2, 2.5, .3), DOOR_POS, Color("8b5b37"))
	door_mesh = door_body.get_node("Mesh")
	container_body = _target("container", "Container", Vector3(.8, .8, .8), BOX_START, Color("307c9a"))
	container_collision = container_body.get_node("Collision")
	_target("chamber_a", "BayA", Vector3(2, .25, 2), BAY_A, Color("8c6136"))
	_target("chamber_b", "BayB", Vector3(2, .25, 2), BAY_B, Color("285f78"))
	_target("elevator", "Elevator", Vector3(1.2, 2.2, .25), Vector3(0, 1.2, 7.7), Color("51616a"))
	_world_label("A-17 / AMBER", BAY_A + Vector3(0, 1.3, 0), Color("d89a55"))
	_world_label("B-04 / BLUE", BAY_B + Vector3(0, 1.3, 0), Color("5eb5dd"))
	_world_label("SHIFT EXIT", Vector3(0, 2.6, 7.5), Color("b9d6c8"))
	observer_visual = _observer_mesh("Observer", OBSERVER_POINTS[0], Color("d7d1bb"))
	for z in [-6.5, -3.0, 1.0, 5.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(0, 2.7, z)
		light.light_color = Color("c7ded8")
		light.omni_range = 6
		light.light_energy = 1.8
		lights.append(light)
		add_child(light)

func _box(n: String, size: Vector3, pos: Vector3, color: Color, collision_enabled: bool) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = n
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	visual.material_override = mat
	add_child(visual)
	if collision_enabled:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		visual.add_child(body)
	return visual

func _target(id: String, n: String, size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = n
	body.position = pos
	body.set_meta("interaction_id", id)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	visual.material_override = mat
	body.add_child(visual)
	add_child(body)
	targets[id] = body
	return body

func _world_label(value: String, pos: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.modulate = color
	label.font_size = 40
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func _observer_mesh(node_name: String, pos: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.42
	mesh.height = 0.84
	visual.mesh = mesh
	visual.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.22
	visual.material_override = material
	add_child(visual)
	return visual

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	lobby_panel = PanelContainer.new()
	lobby_panel.position = Vector2(32, 32)
	lobby_panel.size = Vector2(430, 300)
	var lobby := VBoxContainer.new()
	lobby.add_theme_constant_override("separation", 12)
	lobby_panel.add_child(lobby)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 24)
	lobby.add_child(title_label)
	var language_row := HBoxContainer.new()
	language_label = Label.new()
	language_row.add_child(language_label)
	language_option = OptionButton.new()
	language_option.add_item("Русский")
	language_option.add_item("English")
	language_option.selected = 0 if Localization.locale == "ru" else 1
	language_option.item_selected.connect(_language_selected)
	language_row.add_child(language_option)
	lobby.add_child(language_row)
	address_edit = LineEdit.new()
	address_edit.text = "127.0.0.1"
	lobby.add_child(address_edit)
	host_button = Button.new()
	host_button.pressed.connect(_host)
	lobby.add_child(host_button)
	join_button = Button.new()
	join_button.pressed.connect(_join)
	lobby.add_child(join_button)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lobby.add_child(status_label)
	canvas.add_child(lobby_panel)
	hud = VBoxContainer.new()
	hud.position = Vector2(24, 20)
	hud.size = Vector2(720, 210)
	instruction_label = Label.new()
	instruction_label.add_theme_font_size_override("font_size", 20)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(instruction_label)
	evidence_label = Label.new()
	evidence_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(evidence_label)
	controls_label = Label.new()
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(controls_label)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(timer_label)
	hud.visible = false
	canvas.add_child(hud)
	prompt_label = Label.new()
	prompt_label.position = Vector2(420, 410)
	prompt_label.size = Vector2(440, 60)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(prompt_label)
	log_label = RichTextLabel.new()
	log_label.position = Vector2(24, 535)
	log_label.size = Vector2(850, 160)
	canvas.add_child(log_label)
	result_panel = PanelContainer.new()
	result_panel.position = Vector2(390, 230)
	result_panel.size = Vector2(500, 240)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 24)
	var result_content := VBoxContainer.new()
	result_content.add_child(result_label)
	restart_button = Button.new()
	restart_button.pressed.connect(_request_restart)
	result_content.add_child(restart_button)
	result_panel.add_child(result_content)
	result_panel.visible = false
	canvas.add_child(result_panel)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(635, 350)
	crosshair.add_theme_font_size_override("font_size", 22)
	canvas.add_child(crosshair)
	_refresh_language()

func _language_selected(index: int) -> void:
	Localization.set_locale("ru" if index == 0 else "en")

func _on_language_changed(_locale: String) -> void:
	_refresh_language()

func _refresh_language() -> void:
	title_label.text = Localization.text("title")
	language_label.text = Localization.text("language") + ":"
	address_edit.placeholder_text = Localization.text("server_address")
	host_button.text = Localization.text("host")
	join_button.text = Localization.text("join")
	controls_label.text = Localization.text("controls")
	restart_button.text = Localization.text("restart")
	_update_timer_label(round_time_remaining)
	if not round_started:
		status_label.text = Localization.text("start_hint")
	elif task_resolved:
		instruction_label.text = Localization.text("task_success" if containment_success else "task_failure")
		evidence_label.text = Localization.text("return_to_elevator")
	else:
		_apply_perception()
	if round_finished:
		result_label.text = Localization.text("result_success" if containment_success else "result_failure")

func _host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		status_label.text = Localization.text("host_error", [error_string(error)])
		return
	multiplayer.multiplayer_peer = peer
	round_started = true
	_start_round()
	spawn_player.rpc(1)
	_log(Localization.text("log_host", [PORT]))

func _join() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address_edit.text.strip_edges(), PORT)
	if error != OK:
		status_label.text = Localization.text("join_error", [error_string(error)])
		return
	multiplayer.multiplayer_peer = peer
	status_label.text = Localization.text("connecting")

func _on_connected() -> void:
	round_started = true
	_start_round()
	_log(Localization.text("log_client", [multiplayer.get_unique_id()]))

func _on_connection_failed() -> void:
	status_label.text = Localization.text("connection_failed")

func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server(): return
	for existing_id in players.keys(): spawn_player.rpc_id(id, existing_id)
	spawn_player.rpc(id)
	_sync_state.rpc_id(id, door_open, verification_charges, container_carrier, container_position, task_resolved, containment_success, power_online, observer_point_index, observer_move_count, observer_breached, round_time_remaining)
	_log_key.rpc("log_entered", [id])

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	if multiplayer.is_server() and container_carrier == id:
		container_carrier = 0
		_set_container.rpc(container_position, 0)
	_log(Localization.text("log_disconnected", [id]))

func _start_round() -> void:
	lobby_panel.visible = false
	hud.visible = true
	_apply_perception()

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int) -> void:
	if players.has(id): return
	var player := ShiftPlayer.new()
	add_child(player)
	player.global_position = Vector3(-.8 + players.size() * 1.2, 0, 5)
	player.configure(id, id == multiplayer.get_unique_id())
	players[id] = player
	_apply_perception()

func relay_player_transform(id: int, pos: Vector3, yaw: float) -> void:
	if multiplayer.is_server(): _apply_player_transform.rpc(id, pos, yaw)

@rpc("authority", "call_remote", "unreliable", 1)
func _apply_player_transform(id: int, pos: Vector3, yaw: float) -> void:
	if id != multiplayer.get_unique_id() and players.has(id):
		players[id].global_position = pos
		players[id].rotation.y = yaw

@rpc("authority", "call_remote", "reliable")
func _sync_state(remote_door: bool, charges: int, carrier: int, pos: Vector3, resolved: bool, success: bool, online: bool, observer_index: int, moves: int, breached: bool, time_left: float) -> void:
	_apply_door(remote_door)
	verification_charges = charges
	task_resolved = resolved
	containment_success = success
	power_online = online
	observer_point_index = observer_index
	observer_move_count = moves
	observer_breached = breached
	round_time_remaining = time_left
	_set_container(pos, carrier)
	_apply_power()
	observer_visual.global_position = OBSERVER_POINTS[observer_point_index]
	_update_timer_label(round_time_remaining)

func _apply_perception() -> void:
	if not round_started or instruction_label == null: return
	var local_id := multiplayer.get_unique_id()
	if is_instance_valid(perception_overlay): perception_overlay.queue_free()
	if is_instance_valid(false_observer_visual): false_observer_visual.queue_free()
	if local_id == 1:
		instruction_label.text = Localization.text("order_a")
		evidence_label.text = Localization.text("perception_a")
		door_mesh.visible = true
	else:
		instruction_label.text = Localization.text("order_b")
		evidence_label.text = Localization.text("perception_b")
		door_mesh.visible = false
		perception_overlay = _box("LocalWall", Vector3(2, 2.5, .34), DOOR_POS, Color("596164"), false)
		false_observer_visual = _observer_mesh("FalseObserver", Vector3(-2.1, 0.8, 4.0), Color("b7a7ce"))

func _update_observer(delta: float) -> void:
	if _observer_is_watched():
		observer_unseen_time = 0.0
		return
	observer_unseen_time += delta
	if observer_unseen_time < observer_move_delay:
		return
	observer_unseen_time = 0.0
	observer_point_index = (observer_point_index + 1) % OBSERVER_POINTS.size()
	_set_observer_position.rpc(observer_point_index)

func _observer_is_watched() -> bool:
	for value in players.values():
		var player: ShiftPlayer = value
		var eye_position := player.global_position + Vector3.UP * 1.55
		var offset := observer_visual.global_position - eye_position
		if offset.length() <= 8.0:
			var forward := -player.global_transform.basis.z
			if forward.dot(offset.normalized()) > 0.84 and _has_clear_observer_view(player, eye_position):
				return true
	return false

func _has_clear_observer_view(player: ShiftPlayer, eye_position: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(eye_position, observer_visual.global_position)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

@rpc("authority", "call_local", "reliable")
func _set_observer_position(point_index: int) -> void:
	observer_point_index = point_index
	observer_move_count += 1
	var tween := create_tween()
	tween.tween_property(observer_visual, "scale", Vector3.ZERO, 0.12)
	tween.tween_callback(_teleport_observer.bind(point_index))
	tween.tween_property(observer_visual, "scale", Vector3.ONE, 0.18)
	_log(Localization.text("log_observer_moved"))
	if multiplayer.is_server() and not observer_breached and observer_move_count >= OBSERVER_BREACH_MOVES:
		observer_breached = true
		_observer_breach.rpc()

func _teleport_observer(point_index: int) -> void:
	observer_visual.global_position = OBSERVER_POINTS[point_index]

@rpc("authority", "call_local", "reliable")
func _observer_breach() -> void:
	observer_breached = true
	evidence_label.text = Localization.text("observer_breach")
	_log(Localization.text("log_observer_breach"))
	if power_online:
		power_online = false
		_apply_power()

func update_interaction_prompt(id: String, carrying: bool) -> void:
	if id.is_empty() or round_finished:
		prompt_label.text = ""
		return
	var key := "prompt_" + id
	if carrying and id == "chamber_a": key = "prompt_deposit_a"
	if carrying and id == "chamber_b": key = "prompt_deposit_b"
	prompt_label.text = Localization.text(key)

func request_interaction(peer_id: int, id: String) -> void:
	if multiplayer.is_server(): _server_interact(peer_id, id)
	else: _request_interaction.rpc_id(1, id)

@rpc("any_peer", "call_remote", "reliable")
func _request_interaction(id: String) -> void:
	if multiplayer.is_server(): _server_interact(multiplayer.get_remote_sender_id(), id)

func _server_interact(peer_id: int, id: String) -> void:
	if round_finished or not players.has(peer_id) or not targets.has(id): return
	if players[peer_id].global_position.distance_to(targets[id].global_position) > RANGE:
		_log_key.rpc("log_out_of_range", [peer_id])
		return
	match id:
		"door":
			door_open = not door_open
			_set_door.rpc(door_open, peer_id)
		"container":
			if container_carrier == 0 and not task_resolved:
				container_carrier = peer_id
				_set_container.rpc(container_position, peer_id)
				_log_key.rpc("log_pickup", [peer_id])
		"chamber_a", "chamber_b":
			if container_carrier == peer_id and not task_resolved: _resolve_task(id, peer_id)
		"elevator":
			if task_resolved:
				round_finished = true
				_finish_round.rpc(containment_success and not observer_breached, false)
			else: _log_key.rpc("log_elevator_locked")

@rpc("authority", "call_local", "reliable")
func _set_door(open: bool, peer_id: int) -> void:
	_apply_door(open)
	_log(Localization.text("log_door", [Localization.text("open" if open else "closed"), peer_id]))

func _apply_door(open: bool) -> void:
	door_open = open
	door_body.position.y = 4 if open else DOOR_POS.y

@rpc("authority", "call_local", "unreliable", 2)
func _set_container(pos: Vector3, carrier: int) -> void:
	container_position = pos
	container_carrier = carrier
	container_body.global_position = pos
	container_collision.disabled = carrier != 0

func _resolve_task(id: String, peer_id: int) -> void:
	task_resolved = true
	containment_success = id == "chamber_b"
	container_carrier = 0
	container_position = (BAY_B if containment_success else BAY_A) + Vector3.UP * .55
	_set_container.rpc(container_position, 0)
	if not containment_success:
		power_online = false
		_set_power.rpc(false)
	_task_result.rpc(containment_success, peer_id)

@rpc("authority", "call_local", "reliable")
func _task_result(success: bool, peer_id: int) -> void:
	task_resolved = true
	containment_success = success
	instruction_label.text = Localization.text("task_success" if success else "task_failure")
	evidence_label.text = Localization.text("return_to_elevator")
	_log(Localization.text("log_task_result", [peer_id, Localization.text("success" if success else "failure")]))

@rpc("authority", "call_local", "reliable")
func _set_power(online: bool) -> void:
	power_online = online
	_apply_power()
	_log(Localization.text("log_power_failure"))

func _apply_power() -> void:
	for light in lights:
		light.light_color = Color("c7ded8") if power_online else Color("a51f18")
		light.light_energy = 1.8 if power_online else .65

func _update_round_timer(delta: float) -> void:
	round_time_remaining = maxf(0.0, round_time_remaining - delta)
	timer_sync_accumulator += delta
	if timer_sync_accumulator >= 0.25:
		timer_sync_accumulator = 0.0
		_sync_timer.rpc(round_time_remaining)
	if round_time_remaining <= 0.0:
		round_finished = true
		_finish_round.rpc(false, true)

@rpc("authority", "call_local", "unreliable", 3)
func _sync_timer(time_left: float) -> void:
	round_time_remaining = time_left
	_update_timer_label(time_left)

func _update_timer_label(time_left: float) -> void:
	if timer_label == null:
		return
	var total_seconds := maxi(0, ceili(time_left))
	timer_label.text = Localization.text("timer", [floori(total_seconds / 60.0), total_seconds % 60])

func request_verification(peer_id: int) -> void:
	if multiplayer.is_server(): _server_verify(peer_id)
	else: _request_verification.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_verification() -> void:
	if multiplayer.is_server(): _server_verify(multiplayer.get_remote_sender_id())

func _server_verify(peer_id: int) -> void:
	if verification_charges <= 0:
		_log_key.rpc("log_charge_spent")
		return
	if not players.has(peer_id) or players[peer_id].global_position.distance_to(container_position) > 4:
		_log_key.rpc("log_scanner_far", [peer_id])
		return
	verification_charges = 0
	_reveal_evidence.rpc(peer_id)

@rpc("authority", "call_local", "reliable")
func _reveal_evidence(peer_id: int) -> void:
	verification_charges = 0
	evidence_label.text = Localization.text("verified_container")
	_log(Localization.text("log_verified", [peer_id]))

@rpc("authority", "call_local", "reliable")
func _finish_round(success: bool, timed_out: bool) -> void:
	round_finished = true
	containment_success = success
	result_label.text = Localization.text("result_timeout" if timed_out else ("result_success" if success else "result_failure"))
	result_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _request_restart() -> void:
	if multiplayer.is_server():
		_reset_round.rpc()
	else:
		_request_restart_on_server.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _request_restart_on_server() -> void:
	if multiplayer.is_server() and round_finished:
		_reset_round.rpc()

@rpc("authority", "call_local", "reliable")
func _reset_round() -> void:
	door_open = false
	verification_charges = 1
	container_carrier = 0
	container_position = BOX_START
	task_resolved = false
	containment_success = false
	power_online = true
	round_finished = false
	observer_point_index = 0
	observer_move_count = 0
	observer_breached = false
	observer_unseen_time = 0.0
	round_time_remaining = ROUND_DURATION
	timer_sync_accumulator = 0.0
	_apply_door(false)
	_set_container(BOX_START, 0)
	observer_visual.global_position = OBSERVER_POINTS[0]
	observer_visual.scale = Vector3.ONE
	_apply_power()
	for id in players.keys():
		players[id].global_position = Vector3(-0.8 + players.keys().find(id) * 1.2, 0.0, 5.0)
	result_panel.visible = false
	prompt_label.text = ""
	log_label.clear()
	_apply_perception()
	_update_timer_label(round_time_remaining)
	if players.has(multiplayer.get_unique_id()):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_log(Localization.text("log_round_restarted"))

@rpc("authority", "call_local", "reliable")
func _log_key(key: String, values: Array = []) -> void:
	_log(Localization.text(key, values))

func _log(message: String) -> void:
	print(message)
	if log_label != null: log_label.append_text(message + "\n")
