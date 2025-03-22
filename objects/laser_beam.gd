extends GameTile
class_name LaserBeam

var SL = 4
var LIVES = SL

const BEAMCLASS = preload("res://objects/LaserBeam.tscn")

func updateDir():
	var rot = global_rotation_degrees
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

func _ready() -> void:
	updateDir()

func _process(delta):
	pass

func _physics_process(delta: float) -> void:
	'''
	var ORIGIN = get_meta("ORIGIN")
	if ORIGIN == null or get_node(ORIGIN) == null:
		print("NULL ORIGIN")
		kill()
		return
	if get_node(ORIGIN) is Laser and not get_node(ORIGIN).get_meta("ACTIVE"):
		print("NOT ACTIVE")
		kill()
		return
	'''
	
	var LEFT_EXISTS = false
	
	for body in $L.get_overlapping_areas():
		if body.get_parent() is LaserBeam:
			LEFT_EXISTS = true
			break
		if body.get_parent() is Laser and body.get_parent().get_meta("ACTIVE"):
			LEFT_EXISTS = true
			break
	
	if not LEFT_EXISTS:
		print("LEFT DOES NOT EXIST")
		kill()
		return
	
	var RIGHT_EXISTS = false
	for body in $R2.get_overlapping_areas():
		if body.get_parent() == self:
			continue
		if body.get_parent() is LaserBeam and body.get_parent().get_meta("DIR") == get_meta("DIR"):
			RIGHT_EXISTS = true
			break
	
	for body in $R2.get_overlapping_bodies():
		if not body.get_parent() is GameTile:
			continue
		if body.get_parent().isLaserBlocker():
			RIGHT_EXISTS = true
			break
	
# print(position, "RIGHT/LEFT", RIGHT_EXISTS, LEFT_EXISTS)
		
	if not RIGHT_EXISTS:
				var Beam: LaserBeam = BEAMCLASS.instantiate()
				Beam.global_position = global_position + Vector2(get_meta("DIR")) * GlobalVariables.CELL_SIZE
				Beam.global_rotation = global_rotation
				add_child(Beam)
				Beam.global_position = global_position + Vector2(get_meta("DIR")) * GlobalVariables.CELL_SIZE
				Beam.global_rotation = global_rotation
				Beam.updateDir()
				print(self, "NEW BEAM", Beam.global_position, Beam.get_meta("DIR"), Beam.global_rotation_degrees, get_meta("DIR"), global_rotation_degrees)
				
	for tile in $AreaX.get_overlapping_bodies():
		if tile.get_parent() is LaserBeam and tile.get_parent().get_meta("DIR") == get_meta("DIR") and tile.get_parent().name < name:
			print(name, "OVERLAPPING SAME BEAM")
			kill()
			return
		if tile.get_parent().isLaserBlocker():
			print("OVERLAPPING BLOCKER")
			kill()
			return
			
	for tile in $AreaX.get_overlapping_areas():
		if tile.get_parent() is LaserBeam and tile.get_parent().get_meta("DIR") == get_meta("DIR") and tile.get_parent().name < name:
			print(position, "OVERLAPPING SAME BEAM")
			kill()
			return
		if tile.get_parent() is GameTile and tile.get_parent().isLaserBlocker():
			print("OVERLAPPING BLOCKER")
			kill()
			return
			
	for tile in $AreaX.get_overlapping_bodies():
		if tile.get_parent().isLaserBlocker():
			print("OVERLAPPING BLOCKER")
			kill()
			return
		tile.get_parent().set_meta("SYMBOL", GameTile.NULL_SYMBOL)
		tile.get_parent().set_meta("LAYERS", 0)
		tile.get_parent().set_meta("NO_SYMBOL", true)
	LIVES = SL
	
func kill():
	LIVES -= 1
	if LIVES < 0:
		for tile in $AreaX.get_overlapping_bodies():
				tile.get_parent().set_meta("NO_SYMBOL", false)
		print(position, "BEAM KILLED")
		queue_free()
	
