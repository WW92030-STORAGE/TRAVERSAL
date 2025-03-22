extends Node2D

@onready var TILES = $Tiles.get_children()

enum CAM_METHODS {FLUID, END, SOURCE} # How the camera data will be calculated
var CAM_METHOD_LIST = [CAM_METHODS.FLUID, CAM_METHODS.END, CAM_METHODS.SOURCE]

var CAM_METHOD = 0
var CAM_INDEX = 0 # The endpoint/source to pull depths from

var Button2 = false
var Button3 = false

var LEVEL_COMPLETED = false

var UI_TIMER = 0

func _ready():
	UI_TIMER = Time.get_ticks_msec()
	initSourcesEnds()
			
	print(GlobalVariables.SOURCES)
	print(GlobalVariables.ENDS)
			
	calcEndDepths()
	calcSourceDepths()
	
	GlobalVariables.START_TIME = Time.get_ticks_msec()
	GlobalVariables.END_TIME = GlobalVariables.START_TIME
	GlobalVariables.FLUID_TILES = 0
	GlobalVariables.CELLS_BROKEN = 0
	GlobalVariables.LONGEST_RUN = 0
	
	$Viewport/LevelCompleted.hide()
	$Viewport/BGElement.show()
	$Viewport/UI.show()
	$Viewport/Screen.show()
	$Viewport.show()
	
	$Tiles.show()
	$Explosion/CollisionShape2D/Sprite2D.show()
	$Explosion/CollisionShape2D/Sprite2D.set_modulate(Color(0, 0, 0, 0))

var FP = false

func _process(delta: float) -> void:
	setCamera()
	
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_P):
		Exit()
		
	if Input.is_key_pressed(KEY_F):
		if not FP:
			GlobalVariables.PULSE_TILES = not GlobalVariables.PULSE_TILES
			FP = true
	else:
		FP = false
	
	if Input.is_mouse_button_pressed(1):
		var HELD = null
		for tile in TILES:
			if tile.IS_HELD:
				HELD = tile
		if HELD != null:
			if not GlobalVariables.HOLDING:
				GlobalVariables.HOLDING = true
				GlobalVariables.SELECTED.append(HELD)
				GlobalVariables.HELD_SYMBOL = HELD.get_meta("SYMBOL")
			else:
				if HELD.get_meta("SYMBOL") == GlobalVariables.HELD_SYMBOL:
					var Neighboring = false
					var Pop = false
					for link in HELD.getLinks():
						if link == GlobalVariables.SELECTED[-1]:
							Neighboring = true
							if link == GlobalVariables.SELECTED[-1] and HELD in GlobalVariables.SELECTED:
								Pop = true
					if Neighboring and HELD not in GlobalVariables.SELECTED:
						GlobalVariables.SELECTED.append(HELD)
					if Pop:
						GlobalVariables.SELECTED.pop_back()
		
		if (len(GlobalVariables.SELECTED) > 0):
			$Explosion.position = GlobalVariables.SELECTED[-1].position
			$Explosion/CollisionShape2D/Sprite2D.position = $Explosion.position
					
	else: # Not holding mouse button
		
		if len(GlobalVariables.SELECTED) >= GlobalVariables.MIN_HOLD:
			GlobalVariables.LONGEST_RUN = max(GlobalVariables.LONGEST_RUN, len(GlobalVariables.SELECTED))
			
			for tile in GlobalVariables.SELECTED:
				if tile.get_meta("LAYERS") > 0:
					tile.set_meta("LAYERS", tile.get_meta("LAYERS") - 1)
					GlobalVariables.CELLS_BROKEN += 1
				tile.set_meta("SYMBOL", GameTile.NULL_SYMBOL)
				tile.UpdateFluid()
			calcSourceDepths()
			calcEndDepths()
		
		if len(GlobalVariables.SELECTED) >= GlobalVariables.MIN_EXP:
			$Explosion/CollisionShape2D/Sprite2D.set_modulate(Color(1, 1, 1, 1))
			print("EXPLODE")
			# print(GlobalVariables.SELECTED)
			$Explosion.position = GlobalVariables.SELECTED[-1].global_position
			$Explosion/CollisionShape2D/Sprite2D.position = $Explosion.position
			var overlaps = $Explosion.get_overlapping_bodies()
			print("OVERLAPS", overlaps)
			for tile in overlaps:
				if tile.get_parent() in GlobalVariables.SELECTED:
					continue
				print("EXPLODING " + str(tile.get_parent()))
				tile.get_parent().Explode()
				
			
		
		
		GlobalVariables.HOLDING = false
		GlobalVariables.SELECTED = []
		
		
	# Reshuffle if necessary
	if not isMoveOnScreen():
		resetOnScreenTiles()
		
	# Set the camera data
	$Viewport/UI/CamData.text = GlobalVariables.CAM_INFO
	changeConfig()
	
	# End the level
	if LevelCompleted():
		EndLevel()
		
	# Fade out the explosion
	var m = $Explosion/CollisionShape2D/Sprite2D.get_modulate()
	if m.a > 0:
		$Explosion/CollisionShape2D/Sprite2D.set_modulate(Color(m.r, m.g, m.b, m.a - 0.01))
	else:
		$Explosion/CollisionShape2D/Sprite2D.set_modulate(Color(m.r, m.g, m.b, 0))
		
# Get all tiles visible and interactable.
func getTilesOnScreen(): 
	var res = []
	for tile in $Viewport/Screen.get_overlapping_bodies():
		res.append(tile.get_parent())
	return res

# Search for a legal on-screen move with a given source tile and a list of all visible tiles.
func searchForMove(tile, OST):
	if tile.NoSymbol() or not tile.isNormalTile():
		return false
	var depths = {}
	var q = [tile]
	
	depths[tile] = 1
	
	while len(q) > 0:
		var now = q[0]
		q.pop_front()
		for v in now.getLinks():
			if v == null:
				continue
			if v in depths:
				continue
			if not v in OST:
				continue
			if v.get_meta("SYMBOL") != now.get_meta("SYMBOL"):
				continue
			if not v.isNormalTile() or v.NoSymbol():
				continue
			depths[v] = 1 + depths[now]
			q.append(v)
		
	for depth in depths:
		if depths[depth] >= GlobalVariables.MIN_HOLD:
			return true
	return false

# Does there exist a legal move on screen?
func isMoveOnScreen():
	var OST = getTilesOnScreen()
	for tile in OST:
		
		if searchForMove(tile, OST):
			# print("MOVE DETECTED", tile.position, tile.get_meta("SYMBOL"), )
			return true
	return false

# Reshuffle all on screen tiles
func resetOnScreenTiles():
	for tile in getTilesOnScreen():
		if tile.isNormalTile() and not tile.get_meta("NOT_REPLACABLE"):
			tile.set_meta("SYMBOL", GameTile.randomSymbol())
			# tile.set_meta("SYMBOL", GameTile.NULL_SYMBOL)

# Initialize lists of sources and ends
func initSourcesEnds():
	GlobalVariables.SOURCES = []
	GlobalVariables.ENDS = []
	for tile in TILES:
		if tile.get_meta("SOURCE"):
			GlobalVariables.SOURCES.append(tile)
		if tile.get_meta("END"):
			GlobalVariables.ENDS.append(tile)

# Calculate depths of tiles relative to each end
func calcEndDepths():
	GlobalVariables.DISTS_ENDS = {}
	for tile in GlobalVariables.ENDS:
		var depths = {}
		var q = [tile]
		depths[tile] = 0
		while len(q) > 0:
			var now = q[0]
			q.pop_front()
			for v in now.getLinks():
				if v == null:
					continue
				if v in depths:
					continue
				depths[v] = 1 + depths[now]
				q.append(v)
				
		GlobalVariables.DISTS_ENDS[tile] = depths
		
	
# Calculate depths of FLUID tiles relative to each source
func calcSourceDepths():
	GlobalVariables.DISTS_SOURCES = {}
	for tile in GlobalVariables.SOURCES:
		var depths = {}
		var q = [tile]
		depths[tile] = 0
		while len(q) > 0:
			var now = q[0]
			q.pop_front()
			for v in now.getLinks():
				if v == null:
					continue
				if v in depths:
					continue
				if v.get_meta("FLUID") < 0:
					continue
				depths[v] = 1 + depths[now]
				q.append(v)
		GlobalVariables.DISTS_SOURCES[tile] = depths
		
# Move the camera based on the configuration
func setCamera():
	calcEndDepths()
	calcSourceDepths()
	var MD = 0
	var MT = self
	var METHOD = CAM_METHOD_LIST[CAM_METHOD]
	if METHOD == CAM_METHODS.FLUID:
		GlobalVariables.CAM_INFO = "FLUID DEPTH"
		for tile in TILES:
			if tile.get_meta("FLUID") > MD:
				MD = tile.get_meta("FLUID")
				MT = tile
	
	elif METHOD == CAM_METHODS.SOURCE:
		CAM_INDEX = CAM_INDEX % len(GlobalVariables.SOURCES)
		GlobalVariables.CAM_INFO = "SRC " + str(CAM_INDEX) + "/" + str(len(GlobalVariables.SOURCES))
		var DISTS = GlobalVariables.DISTS_SOURCES[GlobalVariables.SOURCES[CAM_INDEX]]
		for tile in DISTS:
			if tile.get_meta("FLUID") < 0:
				continue
			if DISTS[tile] > MD:
				MD = DISTS[tile]
				MT = tile
	
	elif METHOD == CAM_METHODS.END:
		MD = len(TILES) * 4
		CAM_INDEX = CAM_INDEX % len(GlobalVariables.ENDS)
		GlobalVariables.CAM_INFO = "END " + str(CAM_INDEX) + "/" + str(len(GlobalVariables.ENDS))
		# print("INDEX " + str(CAM_INDEX))
		var DISTS = GlobalVariables.DISTS_ENDS[GlobalVariables.ENDS[CAM_INDEX]]
		# print(DISTS)
		for tile in DISTS:
			if tile.get_meta("FLUID") < 0:
				continue
			if DISTS[tile] < MD:
				MD = DISTS[tile]
				MT = tile
	
	
	else:
		GlobalVariables.CAM_INFO = "NULL"
	
	$Viewport.global_position = MT.global_position
	
# Change camera configuration
func changeConfig():
	if Time.get_ticks_msec() - 1500 > UI_TIMER:
		$Viewport/UI.hide()
	else:
		$Viewport/UI.show()
	
	
	if Input.is_mouse_button_pressed(2):
		UI_TIMER = Time.get_ticks_msec()
		if not Button2:
			CAM_INDEX = 0
			CAM_METHOD = (CAM_METHOD + 1) % len(CAM_METHODS)
		Button2 = true
	else:
		Button2 = false
		
		
		
		
	
	if Input.is_mouse_button_pressed(3):
		UI_TIMER = Time.get_ticks_msec()
		if not Button3:
			var METHOD = CAM_METHOD_LIST[CAM_METHOD]
			if METHOD == CAM_METHODS.SOURCE:
				CAM_INDEX = (1 + CAM_INDEX) % len(GlobalVariables.SOURCES)
			if METHOD == CAM_METHODS.END:
				CAM_INDEX = (1 + CAM_INDEX) % len(GlobalVariables.ENDS)
		Button3 = true
	else:
		Button3 = false

func LevelCompleted():
	for end in GlobalVariables.ENDS:
		if end.get_meta("FLUID") < 0:
			return false
	return true

func EndLevel():
	if LEVEL_COMPLETED:
		if Input.is_key_pressed(KEY_R):
			Exit()
		return
	LEVEL_COMPLETED = true
	$Viewport/AudioStreamPlayer2D.stop()
	$Viewport/UI.hide()
	
	
	$Viewport/LevelCompleted.show()
	GlobalVariables.END_TIME = Time.get_ticks_msec()
	$Viewport/LevelCompleted/VBoxContainer/TIME.text = "TIME-" + str((GlobalVariables.END_TIME - GlobalVariables.START_TIME) * 0.001) + " SEC"
	$Viewport/LevelCompleted/VBoxContainer/CELLS.text = "CELLS BROKEN-" + str(GlobalVariables.CELLS_BROKEN)
	
	var FLUIDS = 0
	for tile in TILES:
		if tile.get_meta("FLUID") >= 0:
			FLUIDS += 1
	GlobalVariables.FLUID_TILES = FLUIDS
	$Viewport/LevelCompleted/VBoxContainer/FLUID.text = "FLUID TILES-" + str(GlobalVariables.FLUID_TILES)
	
	$Viewport/LevelCompleted/VBoxContainer/RUN.text = "LONGEST RUN-" + str(GlobalVariables.LONGEST_RUN)

func Exit():
	get_tree().change_scene_to_file("res://menu/level_selection.tscn") 
