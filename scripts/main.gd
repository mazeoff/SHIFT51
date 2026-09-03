extends Node3D

const PORT := 5151
const MAX_PLAYERS := 4
const DOOR_POSITION := Vector3(0.0, 1.25, -6.0)
const INTERACTION_DISTANCE := 3.2
const PLAYER_SCRIPT := preload("res://scripts/player.gd")

var players: Dictionary = {}
var door_open := false
var verification_used := false
var round_started := false
var door_body: StaticBody3D
var door_mesh: MeshInstance3D
var perception_overlay: MeshInstance3D
var lobby_panel: PanelContainer
var hud: VBoxContainer
var status_label: Label
var instruction_label: Label
var evidence_label: Label
var log_label: RichTextLabel
var address_edit: LineEdit
var title_label: Label
var language_label: Label
var language_option: OptionButton
var host_button: Button
var join_button: Button
var controls_label: Label

func _ready() -> void:
	_build_environment()
	_build_ui()
	Localization.language_changed.connect(_on_language_changed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_log(Localization.text("log_initial"))

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("101518")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8ca0a3")
	environment.ambient_light_energy = 0.55
	world_environment.environment = environment
	add_child(world_environment)

	_add_box("Floor", Vector3(6.0, 0.2, 16.0), Vector3(0.0, -0.1, 0.0), Color("343b3d"), true)
	_add_box("Ceiling", Vector3(6.0, 0.2, 16.0), Vector3(0.0, 3.1, 0.0), Color("24292b"), true)
	_add_box("LeftWall", Vector3(0.2, 3.2, 16.0), Vector3(-3.0, 1.5, 0.0), Color("596164"), true)
	_add_box("RightWall", Vector3(0.2, 3.2, 16.0), Vector3(3.0, 1.5, 0.0), Color("596164"), true)
	_add_box("EndWall", Vector3(6.0, 3.2, 0.2), Vector3(0.0, 1.5, -8.0), Color("596164"), true)
	_add_box("StartWall", Vector3(6.0, 3.2, 0.2), Vector3(0.0, 1.5, 8.0), Color("596164"), true)
	_add_box("DoorFrameLeft", Vector3(2.0, 3.2, 0.35), Vector3(-2.0, 1.5, -6.0), Color("263033"), true)
	_add_box("DoorFrameRight", Vector3(2.0, 3.2, 0.35), Vector3(2.0, 1.5, -6.0), Color("263033"), true)

	door_body = StaticBody3D.new()
	door_body.name = "AuthoritativeDoor"
	door_body.position = DOOR_POSITION
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 2.5, 0.3)
	collision.shape = shape
	door_body.add_child(collision)
	door_mesh = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	door_mesh.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8b5b37")
	door_mesh.material_override = material
	door_body.add_child(door_mesh)
	add_child(door_body)

	for z in [-4.0, 0.0, 4.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(0.0, 2.7, z)
		light.light_color = Color("c7ded8")
		light.omni_range = 6.0
		light.light_energy = 1.8
		add_child(light)

func _add_box(node_name: String, size: Vector3, position: Vector3, color: Color, collision_enabled: bool) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	add_child(mesh_instance)
	if collision_enabled:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		mesh_instance.add_child(body)
	return mesh_instance

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	lobby_panel = PanelContainer.new()
	lobby_panel.position = Vector2(32, 32)
	lobby_panel.size = Vector2(380, 230)
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
	language_option.item_selected.connect(_on_language_selected)
	language_row.add_child(language_option)
	lobby.add_child(language_row)
	address_edit = LineEdit.new()
	address_edit.text = "127.0.0.1"
	lobby.add_child(address_edit)
	host_button = Button.new()
	host_button.pressed.connect(_host_game)
	lobby.add_child(host_button)
	join_button = Button.new()
	join_button.pressed.connect(_join_game)
	lobby.add_child(join_button)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lobby.add_child(status_label)
	canvas.add_child(lobby_panel)

	hud = VBoxContainer.new()
	hud.position = Vector2(24, 24)
	hud.size = Vector2(560, 180)
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
	hud.visible = false
	hud.name = "HUD"
	canvas.add_child(hud)

	log_label = RichTextLabel.new()
	log_label.position = Vector2(24, 520)
	log_label.size = Vector2(820, 175)
	log_label.bbcode_enabled = true
	log_label.fit_content = false
	canvas.add_child(log_label)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(635, 350)
	crosshair.add_theme_font_size_override("font_size", 22)
	canvas.add_child(crosshair)
	_refresh_language()

func _on_language_selected(index: int) -> void:
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
	if not round_started:
		status_label.text = Localization.text("start_hint")
	else:
		_apply_local_perception()

func _host_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		status_label.text = Localization.text("host_error", [error_string(error)])
		return
	multiplayer.multiplayer_peer = peer
	round_started = true
	_start_local_round()
	spawn_player.rpc(1)
	_log(Localization.text("log_host", [PORT]))

func _join_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address_edit.text.strip_edges(), PORT)
	if error != OK:
		status_label.text = Localization.text("join_error", [error_string(error)])
		return
	multiplayer.multiplayer_peer = peer
	status_label.text = Localization.text("connecting")

func _on_connected_to_server() -> void:
	round_started = true
	_start_local_round()
	_log(Localization.text("log_client", [multiplayer.get_unique_id()]))

func _on_connection_failed() -> void:
	status_label.text = Localization.text("connection_failed")

func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	for existing_id in players.keys():
		spawn_player.rpc_id(id, existing_id)
	spawn_player.rpc(id)
	_log_key_event.rpc("log_entered", [id])

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	_log(Localization.text("log_disconnected", [id]))

func relay_player_transform(player_id: int, player_position: Vector3, player_yaw: float) -> void:
	if multiplayer.is_server():
		_apply_player_transform.rpc(player_id, player_position, player_yaw)

@rpc("authority", "call_remote", "unreliable", 1)
func _apply_player_transform(player_id: int, player_position: Vector3, player_yaw: float) -> void:
	if player_id == multiplayer.get_unique_id() or not players.has(player_id):
		return
	players[player_id].global_position = player_position
	players[player_id].rotation.y = player_yaw

func _start_local_round() -> void:
	lobby_panel.visible = false
	hud.visible = true
	_apply_local_perception()

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int) -> void:
	if players.has(id):
		return
	var player := ShiftPlayer.new()
	add_child(player)
	player.global_position = Vector3(-0.8 + players.size() * 1.2, 0.0, 5.5)
	player.configure(id, id == multiplayer.get_unique_id())
	players[id] = player
	_apply_local_perception()

func _apply_local_perception() -> void:
	if not round_started or instruction_label == null:
		return
	var local_id := multiplayer.get_unique_id()
	if is_instance_valid(perception_overlay):
		perception_overlay.queue_free()
		perception_overlay = null
	if local_id == 1:
		instruction_label.text = Localization.text("order_a")
		evidence_label.text = Localization.text("perception_a")
		door_mesh.visible = true
	else:
		instruction_label.text = Localization.text("order_b")
		evidence_label.text = Localization.text("perception_b")
		door_mesh.visible = false
		perception_overlay = _add_box("LocalWallPerception", Vector3(2.0, 2.5, 0.34), DOOR_POSITION + Vector3(0.0, 0.0, -0.02), Color("596164"), false)
	_log(Localization.text("log_perception_a" if local_id == 1 else "log_perception_b", [local_id]))

func request_door_interaction(requesting_peer: int, player_position: Vector3) -> void:
	if multiplayer.is_server():
		_server_interact_door(requesting_peer, player_position)
	else:
		_request_door_interaction.rpc_id(1, player_position)

@rpc("any_peer", "call_remote", "reliable")
func _request_door_interaction(player_position: Vector3) -> void:
	if not multiplayer.is_server():
		return
	_server_interact_door(multiplayer.get_remote_sender_id(), player_position)

func _server_interact_door(requesting_peer: int, player_position: Vector3) -> void:
	if player_position.distance_to(DOOR_POSITION) > INTERACTION_DISTANCE:
		_log_key_event.rpc("log_out_of_range", [requesting_peer])
		return
	door_open = not door_open
	_set_door_state.rpc(door_open, requesting_peer)

@rpc("authority", "call_local", "reliable")
func _set_door_state(open: bool, requesting_peer: int) -> void:
	door_open = open
	door_body.position.y = 4.0 if open else DOOR_POSITION.y
	_log(Localization.text("log_door", [Localization.text("open" if open else "closed"), requesting_peer]))

func request_verification(requesting_peer: int, player_position: Vector3) -> void:
	if multiplayer.is_server():
		_server_verify(requesting_peer, player_position)
	else:
		_request_verification.rpc_id(1, player_position)

@rpc("any_peer", "call_remote", "reliable")
func _request_verification(player_position: Vector3) -> void:
	if multiplayer.is_server():
		_server_verify(multiplayer.get_remote_sender_id(), player_position)

func _server_verify(requesting_peer: int, player_position: Vector3) -> void:
	if verification_used:
		_log_key_event.rpc("log_charge_spent")
		return
	if player_position.distance_to(DOOR_POSITION) > 5.0:
		_log_key_event.rpc("log_scanner_far", [requesting_peer])
		return
	verification_used = true
	_reveal_evidence.rpc(requesting_peer, door_open)

@rpc("authority", "call_local", "reliable")
func _reveal_evidence(requesting_peer: int, open: bool) -> void:
	evidence_label.text = Localization.text("verified", [Localization.text("open" if open else "closed")])
	_log(Localization.text("log_verified", [requesting_peer]))

@rpc("authority", "call_local", "reliable")
func _log_key_event(key: String, values: Array = []) -> void:
	_log(Localization.text(key, values))

func _log(message: String) -> void:
	print(message)
	if log_label != null:
		log_label.append_text(message + "\n")
