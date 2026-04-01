## Main menu — title screen with New Game and Quit.
## See: UI System GDD
extends Control


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.1, 0.25)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center container
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.offset_left = -200
	vbox.offset_right = 200
	vbox.offset_top = -180
	vbox.offset_bottom = 180
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "KARNEVAL\nFOREVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Die Kostüme gehen nicht mehr ab..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.75, 0.9))
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 40
	vbox.add_child(spacer)

	# New Game button
	var new_game := Button.new()
	new_game.text = "Neues Spiel"
	new_game.custom_minimum_size.y = 50
	new_game.add_theme_font_size_override("font_size", 22)
	new_game.pressed.connect(_on_new_game)
	vbox.add_child(new_game)

	# Quit button
	var quit := Button.new()
	quit.text = "Beenden"
	quit.custom_minimum_size.y = 50
	quit.add_theme_font_size_override("font_size", 22)
	quit.pressed.connect(_on_quit)
	vbox.add_child(quit)


func _on_new_game() -> void:
	GameState.reset()
	InventoryManager.clear()
	CostumeManager.clear_assignments()
	SceneManager.load_scene("res://scenes/chapter_1.tscn")


func _on_quit() -> void:
	get_tree().quit()
