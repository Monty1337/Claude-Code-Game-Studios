## Interpolates WorldEnvironment post-processing based on curse_level.
## 0.0 = fully cursed (grey, foggy, dim). 1.0 = liberated (vibrant, clear, warm).
## Listens to EventBus.curse_level_changed.
## See: World/Environment GDD
class_name CurseEnvironment
extends WorldEnvironment

@export_group("Cursed State (0.0)")
@export var cursed_fog_density: float = 0.04
@export var cursed_fog_color: Color = Color(0.5, 0.5, 0.55)
@export var cursed_saturation: float = 0.4
@export var cursed_brightness: float = 0.8
@export var cursed_sky_color: Color = Color(0.45, 0.5, 0.6)

@export_group("Liberated State (1.0)")
@export var liberated_fog_density: float = 0.002
@export var liberated_fog_color: Color = Color(0.8, 0.85, 0.95)
@export var liberated_saturation: float = 1.2
@export var liberated_brightness: float = 1.0
@export var liberated_sky_color: Color = Color(0.5, 0.7, 0.95)

@export_group("Transition")
@export var transition_speed: float = 2.0

var _target_level: float = 0.0
var _current_level: float = 0.0


func _ready() -> void:
	EventBus.curse_level_changed.connect(_on_curse_changed)
	_target_level = GameState.get_curse_level()
	_current_level = _target_level
	_apply_level(_current_level)


func _process(delta: float) -> void:
	if absf(_current_level - _target_level) > 0.001:
		_current_level = move_toward(_current_level, _target_level, delta / transition_speed)
		_apply_level(_current_level)


func _on_curse_changed(new_level: float) -> void:
	_target_level = new_level


func _apply_level(level: float) -> void:
	if not environment:
		return

	# Fog
	environment.fog_density = lerpf(cursed_fog_density, liberated_fog_density, level)
	environment.fog_light_color = cursed_fog_color.lerp(liberated_fog_color, level)

	# Sky/background
	environment.background_color = cursed_sky_color.lerp(liberated_sky_color, level)

	# Brightness via ambient light energy
	environment.ambient_light_energy = lerpf(cursed_brightness, liberated_brightness, level)

	# Saturation via adjustment
	environment.adjustment_enabled = true
	environment.adjustment_saturation = lerpf(cursed_saturation, liberated_saturation, level)
