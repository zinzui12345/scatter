@tool
extends Node3D


@export_category("ScatterItem")
@export var proportion := 100
@export_enum("From current scene", "From disk") var source:
	set(val):
		source = val
		property_list_changed.emit()

@export_group("Source options", "source_")
@export var source_scale_multiplier := 1.0
@export var source_ignore_position := true
@export var source_ignore_rotation := true
@export var source_ignore_scale := true

var path: String
var source_position: Vector3
var source_rotation: Vector3
var source_scale: Vector3


func _get_property_list() -> Array:
	var list := []

	if source == 0:
		list.push_back({
			name = "path",
			type = TYPE_NODE_PATH,
		})
	else:
		list.push_back({
			name = "path",
			type = TYPE_STRING,
			hint = PROPERTY_HINT_FILE,
		})

	return list


func get_item() -> Node3D:
	if path.is_empty():
		return null

	var node: Node3D

	if source == 0:
		node = get_node_or_null(path)
	else:
		var scene = load(path)
		if scene:
			node = scene.instantiate()

	if node:
		_save_source_data(node)
		return node

	return null


# Takes a transform in input, scale it based on the local scale multiplier
# If the source transform is not ignored, also copy the source position, rotation and scale.
# Returns the processed transform
func process_transform(t: Transform3D) -> Transform3D:
	var origin = t.origin
	t.origin = Vector3.ZERO

	t = t.scaled(Vector3.ONE * source_scale_multiplier)

	if not source_ignore_scale:
		t = t.scaled(source_scale)

	if not source_ignore_rotation:
		t = t.rotated(t.basis.x.normalized(), source_rotation.x)
		t = t.rotated(t.basis.y.normalized(), source_rotation.y)
		t = t.rotated(t.basis.z.normalized(), source_rotation.z)

	t.origin = origin

	if not source_ignore_position:
		t.origin += source_position

	return t


func _save_source_data(node: Node3D) -> void:
	if not node:
		return

	source_position = node.position
	source_rotation = node.rotation
	source_scale = node.scale
