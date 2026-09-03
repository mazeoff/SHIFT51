class_name InteractionProbe
extends Node

const RAY_DISTANCE := 3.5
var camera: Camera3D
var excluded_rid: RID

func configure(source_camera: Camera3D, body_rid: RID) -> void:
	camera = source_camera
	excluded_rid = body_rid

func target_id() -> String:
	if camera == null:
		return ""
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * RAY_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [excluded_rid]
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ""
	var collider: Object = hit.get("collider")
	if collider != null and collider.has_meta("interaction_id"):
		return str(collider.get_meta("interaction_id"))
	return ""
