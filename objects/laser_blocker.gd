extends GameTile
class_name LaserBlocker

func _ready() -> void:
	$Symbol.set_modulate(Color.RED)

func _process(delta):
	pulseSymbol()

func _physics_process(delta: float) -> void:
	
	
	set_meta("LAYERS", 9999)
