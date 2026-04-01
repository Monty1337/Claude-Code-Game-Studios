## Main game UI — interaction prompts, message box, inventory panel.
## Listens to EventBus signals and renders UI accordingly.
## See: UI System GDD
class_name GameUI
extends CanvasLayer

var _root: Control
var _prompt_label: Label
var _message_panel: PanelContainer
var _message_label: Label
var _inventory_panel: PanelContainer
var _inventory_list: VBoxContainer
var _pause_panel: Control
var _message_timer: float = 0.0
var _paused := false


func _ready() -> void:
	layer = 10

	# Root control fills the screen
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_prompt()
	_build_message_box()
	_build_inventory_panel()
	_build_pause_menu()
	_connect_signals()


func _build_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.offset_top = 40
	_prompt_label.offset_bottom = 80
	_prompt_label.offset_left = -250
	_prompt_label.offset_right = 250
	_prompt_label.add_theme_font_size_override("font_size", 22)
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	_prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	_prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	_prompt_label.visible = false
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_prompt_label)


func _build_message_box() -> void:
	_message_panel = PanelContainer.new()
	_message_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_message_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_message_panel.offset_left = -320
	_message_panel.offset_right = 320
	_message_panel.offset_top = -150
	_message_panel.offset_bottom = -20
	_message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_panel.visible = false
	_root.add_child(_message_panel)

	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message_label.add_theme_font_size_override("font_size", 18)
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_panel.add_child(_message_label)


func _build_inventory_panel() -> void:
	_inventory_panel = PanelContainer.new()
	_inventory_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_inventory_panel.offset_left = -230
	_inventory_panel.offset_right = -10
	_inventory_panel.offset_top = 10
	_inventory_panel.offset_bottom = 300
	_inventory_panel.visible = false
	_inventory_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_inventory_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inventory_panel.add_child(vbox)

	var title := Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	_inventory_list = VBoxContainer.new()
	_inventory_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_inventory_list)


func _build_pause_menu() -> void:
	_pause_panel = Control.new()
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.visible = false
	_root.add_child(_pause_panel)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_panel.add_child(dim)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.offset_left = -150
	vbox.offset_right = 150
	vbox.offset_top = -100
	vbox.offset_bottom = 100
	vbox.add_theme_constant_override("separation", 15)
	_pause_panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Weiterspielen"
	resume_btn.custom_minimum_size.y = 45
	resume_btn.add_theme_font_size_override("font_size", 20)
	resume_btn.pressed.connect(_unpause)
	vbox.add_child(resume_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Hauptmenü"
	menu_btn.custom_minimum_size.y = 45
	menu_btn.add_theme_font_size_override("font_size", 20)
	menu_btn.pressed.connect(_return_to_menu)
	vbox.add_child(menu_btn)


func _connect_signals() -> void:
	EventBus.prompt_show.connect(_on_prompt_show)
	EventBus.prompt_hide.connect(_on_prompt_hide)
	EventBus.show_message.connect(_on_show_message)
	EventBus.item_picked_up.connect(func(_id, _p): _refresh_inventory())
	EventBus.item_used.connect(func(_id, _tid, _s): _refresh_inventory())
	EventBus.puzzle_step_completed.connect(_on_puzzle_step)


func _process(delta: float) -> void:
	if _message_timer > 0:
		_message_timer -= delta
		if _message_timer <= 0:
			_message_panel.visible = false

	if Input.is_action_just_pressed("cancel"):
		if _paused:
			_unpause()
		else:
			_pause()
		return

	if _paused:
		return

	if Input.is_action_just_pressed("inventory"):
		_inventory_panel.visible = not _inventory_panel.visible
		_refresh_inventory()


func _pause() -> void:
	_paused = true
	_pause_panel.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unpause() -> void:
	_paused = false
	_pause_panel.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _return_to_menu() -> void:
	_unpause()
	SceneManager.load_scene("res://scenes/main_menu.tscn")


func _on_prompt_show(text: String, _world_pos: Vector3) -> void:
	_prompt_label.text = text
	_prompt_label.visible = true


func _on_prompt_hide() -> void:
	_prompt_label.visible = false


func _on_show_message(text: String, duration: float) -> void:
	_message_label.text = text
	_message_panel.visible = true
	_message_timer = duration if duration > 0 else 9999.0


func _on_puzzle_step(_puzzle_id: StringName, _step: int) -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 0.84, 0, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)


func _refresh_inventory() -> void:
	for child in _inventory_list.get_children():
		child.queue_free()
	var items := InventoryManager.get_items()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "(empty)"
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_inventory_list.add_child(empty)
	else:
		for item_id in items:
			var label := Label.new()
			label.text = "• " + String(item_id).replace("_", " ").capitalize()
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_inventory_list.add_child(label)
