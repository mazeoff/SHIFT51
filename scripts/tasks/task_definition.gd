class_name TaskDefinition
extends Resource

@export var id: String
@export var artifact_name_key: String
@export_enum("chamber_a", "chamber_b") var correct_chamber := "chamber_b"
@export var container_color := Color("307c9a")
@export var scanner_result_key: String
