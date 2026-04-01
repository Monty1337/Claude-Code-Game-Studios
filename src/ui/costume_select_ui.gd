## In-world costume selection screen.
## Displayed at the start of Chapter 1. Player picks a costume, it's permanent.
## See: Costume System GDD
class_name CostumeSelectUI
extends CanvasLayer

signal costume_selected(costume_id: StringName)

var _root: Control
var _panel: PanelContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 20

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# Dim background
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	# Center panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.offset_left = -250
	_panel.offset_right = 250
	_panel.offset_top = -200
	_panel.offset_bottom = 200
	_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "You wake up and look down...\nWhat costume are you stuck in?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	# Costume buttons
	var available := CostumeManager.get_available_costumes()
	for costume_id in CostumeManager._costume_data.keys():
		var data: Dictionary = CostumeManager.get_costume_data(costume_id)
		var btn := Button.new()
		btn.text = data.get("display_name", str(costume_id)) + "\n" + data.get("description", "")
		btn.custom_minimum_size.y = 60
		btn.add_theme_font_size_override("font_size", 16)

		if costume_id not in available:
			btn.disabled = true
			btn.text += " (taken)"
		else:
			var cid: StringName = costume_id  # Capture for lambda
			btn.pressed.connect(func(): _on_costume_picked(cid))

		vbox.add_child(btn)
		_buttons.append(btn)

	# Show mouse for selection
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_costume_picked(costume_id: StringName) -> void:
	CostumeManager.assign_costume(0, costume_id)  # Player 0 for now
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	costume_selected.emit(costume_id)
	queue_free()
