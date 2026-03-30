# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the investigate-interact-solve loop feel fun?
# Date: 2026-03-30
extends CanvasLayer

var prompt_label: Label
var message_panel: PanelContainer
var message_label: Label
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var message_timer: float = 0.0
var message_persistent := false
var root: Control


func _ready() -> void:
	# Root control that fills the screen — all UI anchors relative to this
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Interaction prompt (top center) ---
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.offset_top = 40
	prompt_label.offset_bottom = 80
	prompt_label.offset_left = -200
	prompt_label.offset_right = 200
	prompt_label.add_theme_font_size_override("font_size", 24)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	prompt_label.visible = false
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(prompt_label)

	# --- Message box (bottom center) ---
	message_panel = PanelContainer.new()
	message_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	message_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	message_panel.offset_left = -320
	message_panel.offset_right = 320
	message_panel.offset_top = -140
	message_panel.offset_bottom = -20
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(message_panel)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel.add_child(message_label)
	message_panel.visible = false

	# --- Inventory panel (right side) ---
	inventory_panel = PanelContainer.new()
	inventory_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inventory_panel.offset_left = -220
	inventory_panel.offset_right = -10
	inventory_panel.offset_top = 10
	inventory_panel.offset_bottom = 300
	inventory_panel.visible = false
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(inventory_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_panel.add_child(vbox)

	var title := Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	inventory_list = VBoxContainer.new()
	inventory_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(inventory_list)

	# Connect signals
	EventBus.prompt_show.connect(_on_prompt_show)
	EventBus.prompt_hide.connect(_on_prompt_hide)
	EventBus.show_message.connect(_on_show_message)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.puzzle_step_completed.connect(_on_puzzle_step)


func _process(delta: float) -> void:
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message_panel.visible = false

	if Input.is_action_just_pressed("inventory"):
		inventory_panel.visible = not inventory_panel.visible
		_refresh_inventory()


func _on_prompt_show(text: String, _pos: Vector3) -> void:
	prompt_label.text = text
	prompt_label.visible = true


func _on_prompt_hide() -> void:
	prompt_label.visible = false


func _on_show_message(text: String, duration: float) -> void:
	message_label.text = text
	message_panel.visible = true
	if duration > 0:
		message_timer = duration
		message_persistent = false
	else:
		message_timer = 0
		message_persistent = true


func _on_item_picked_up(_item_id: StringName, _player: Node) -> void:
	_refresh_inventory()


func _on_puzzle_step(_puzzle_id: StringName, _step: int) -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0.84, 0, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)


func _refresh_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	var items := Inventory.get_items()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "(empty)"
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inventory_list.add_child(empty)
	else:
		for item_id in items:
			var label := Label.new()
			label.text = "• " + String(item_id).replace("_", " ").capitalize()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inventory_list.add_child(label)
