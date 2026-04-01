## Credits screen — shown after completing the game.
extends Control

var _scroll_speed: float = 40.0
var _label: Label
var _can_skip := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.offset_left = -400
	_label.offset_right = 400
	_label.offset_top = 720  # Start below screen
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7))
	_label.text = """


KARNEVAL FOREVER


Die Kostüme gehen nicht mehr ab...
...bis jetzt.



ALAAF!

Dreimol Alaaf!



Developed with

CLAUDE CODE GAME STUDIOS



Game Design, Programming & Dialogue
You + Claude



Engine
Godot 4.6



Inspired by
The real Karneval in Köln
and everyone who has ever been jeck



Special Thanks
To the Köbesse who never stop serving Kölsch
To the Büttenredner who make us laugh
To the Funkenmariechen who never stop dancing
To everyone stuck in their costume
...on purpose



"Et hätt noch immer jot jejange."
(It has always worked out in the end.)

- Kölsches Grundgesetz, §1 -



ALAAF!




Press any key to return to the main menu.


"""
	add_child(_label)

	# Enable skip after 2 seconds
	await get_tree().create_timer(2.0).timeout
	_can_skip = true


func _process(delta: float) -> void:
	_label.offset_top -= _scroll_speed * delta
	_label.offset_bottom -= _scroll_speed * delta

	# Auto-return after credits scroll past
	if _label.offset_bottom < -200:
		_return_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	if _can_skip and event is InputEventKey and event.pressed:
		_return_to_menu()
	if _can_skip and event is InputEventMouseButton and event.pressed:
		_return_to_menu()


func _return_to_menu() -> void:
	set_process(false)
	SceneManager.load_scene("res://scenes/main_menu.tscn")
