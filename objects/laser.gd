extends GameTile
class_name Laser

const BEAMCLASS = preload("res://objects/LaserBeam.tscn")

func _ready() -> void:
	var rot = rotation_degrees
	while (rot < 0):
		rot += 720
	rot = fmod(rot, 360)
	
	if (rot < 45):
		set_meta("DIR", Vector2i(1, 0))
	elif (rot < 135):
		set_meta("DIR", Vector2i(0, 1))
	elif (rot < 225):
		set_meta("DIR", Vector2i(-1, 0))
	elif (rot < 315):
		set_meta("DIR", Vector2i(0, -1))
	else:
		set_meta("DIR", Vector2i(1, 0))

func _process(delta):
	$Symbol.scale = Vector2(1, 1) * lerp(0.1, 0.9, GlobalVariables.VOLUME)

func _physics_process(delta: float) -> void:
	
	set_meta("LAYERS", 0)
	
	var FLUID = get_meta("FLUID")
	
	var IntersectsOtherLaser = false
	for area in $Area2D.get_overlapping_areas():
		if area.get_parent() is LaserBeam:
			IntersectsOtherLaser = true
			break
	
	if (FLUID < 0) and (not IntersectsOtherLaser):
		$Symbol.set_modulate(Color.WHITE)
		$Dir.set_modulate(Color.WHITE)
		set_meta("ACTIVE", false)
	else:
		$Symbol.set_modulate(GlobalVariables.RAINBOW_COLOR)
		$Dir.set_modulate(Color.RED)
		
		set_meta("ACTIVE", true)
		if true:
			var Inhibited = false
			for body in $TrueDir.get_overlapping_bodies():
				if body.get_parent().isLaserBlocker():
					Inhibited = true
					break
			if not Inhibited:
				for area in $TrueDir.get_overlapping_areas():
					if area.get_parent() is LaserBeam and area.get_parent().get_meta("DIR") == get_meta("DIR"):
						Inhibited = true
						break
			if not Inhibited:
			
				var Beam: LaserBeam = BEAMCLASS.instantiate()
				Beam.global_position = global_position + Vector2(get_meta("DIR")) * GlobalVariables.CELL_SIZE
				Beam.global_rotation = global_rotation
				print("NEW BEAM", Beam.global_position, Beam.get_meta("ORIGIN"))
				add_child(Beam)
				Beam.global_position = global_position + Vector2(get_meta("DIR")) * GlobalVariables.CELL_SIZE
				Beam.global_rotation = global_rotation
				Beam.updateDir()
		
		
		set_meta("ACTIVE", true)
		
	UpdateFluid()
	UpdateTileTex()
	
