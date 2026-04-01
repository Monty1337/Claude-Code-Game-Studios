## Handles chapter scene transitions with fade-to-black.
## See: ADR-0001
extends Node

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning := false

const FADE_DURATION := 0.5


func _ready() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100  # On top of everything
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var root_control := Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(root_control)

	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(_fade_rect)


func load_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# Fade to black
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)
	await tween.finished

	# Switch scene
	get_tree().change_scene_to_file(scene_path)

	# Fade from black
	var tween_out := create_tween()
	tween_out.tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)
	await tween_out.finished

	_is_transitioning = false


func is_transitioning() -> bool:
	return _is_transitioning
