extends GameTile
class_name Boulder

func _ready() -> void:
	pass
	
func _process(delta):
	pass

func _physics_process(delta: float) -> void:
	var FLUID = get_meta("FLUID")
	var LAYERS = get_meta("LAYERS")
	
	if LAYERS <= 0:
		$TileTex2.set_modulate(Color(0, 0, 0, 0))
	
	UpdateFluid()
	UpdateTileTex()
		
		
