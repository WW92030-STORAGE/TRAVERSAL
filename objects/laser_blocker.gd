extends GameTile
class_name LaserBlocker

func _ready() -> void:
	$Symbol.set_modulate(Color.RED)

func _process(delta):
	$Symbol.scale = Vector2(1, 1) * lerp(0.1, 0.9, GlobalVariables.VOLUME)

func _physics_process(delta: float) -> void:
	
	
	set_meta("LAYERS", 9999)
