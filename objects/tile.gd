extends Node2D
class_name GameTile

@onready var LINKS = [$R, $U, $L, $D]
var dx = [1, 0, -1, 0]
var dy = [0, 1, 0, -1]

var LINK_DEPTH = [-1, -1, -1, -1]
var LINK_LAYER = [-1, -1, -1, -1]
var IS_HELD = false;

static var NULL_SYMBOL = -1
static var END_SYMBOL = -1000
static var DEAD_SYMBOL = 255
static var BLOCKER_SYMBOL = 254
static var LASER_BLOCK = 253

func isLaserBlocker():
	var SYMBOL = get_meta("SYMBOL")
	return SYMBOL == LASER_BLOCK or self is LaserBlocker
	
func isAlive():
	var SYMBOL = get_meta("SYMBOL")
	return SYMBOL != DEAD_SYMBOL and SYMBOL != BLOCKER_SYMBOL and SYMBOL != LASER_BLOCK

func isNormalTile():
	var SYMBOL = get_meta("SYMBOL")
	return SYMBOL >= 0 and SYMBOL < len(GlobalVariables.SYMBOLS)
	
func isMechanism():
	var SYMBOL = get_meta("SYMBOL")
	if get_meta("END"):
		return true
	return not (isNormalTile or SYMBOL == DEAD_SYMBOL or SYMBOL == BLOCKER_SYMBOL or SYMBOL == LASER_BLOCK)

func isSpecial():
	return self.get_meta("END") or self is Laser or self is LaserBlocker
	
func isMechOrSpecial():
	return isMechanism() or isSpecial()

func hasLaser():
	for body in $Area2D.get_overlapping_areas():
		if body.get_parent() is LaserBeam:
			return true
	return false
	
func _ready() -> void:
	if get_meta("SYMBOL") < 0:
		set_meta("SYMBOL", randomSymbol())
	pass
	
func getLink(index):
	var things = LINKS[index].get_overlapping_bodies()
	for thing in things:
		if thing.get_parent() == self:
			continue
		if thing.get_parent() is LaserBeam:
			continue
		return thing.get_parent()
	return null
	
func getLinks():
	return [getLink(0), getLink(1), getLink(2), getLink(3)]

func getLinkedFluidDepths():
	var res = [-1, -1, -1, -1]
	var LINKS = getLinks()
	for index in range(4):
		var overlaps = LINKS[index]
		if overlaps == null:
			continue
		var FLD = overlaps.get_meta("FLUID")
		if overlaps.get_meta("LAYERS") <= 0:
			res[index] = FLD
	
	return res
	
func getLinkedLayers():
	var res = [-1, -1, -1, -1]
	var LINKS = getLinks()
	for index in range(4):
		var overlaps = LINKS[index]
		if overlaps == null:
			continue
		var FLD = overlaps.get_meta("LAYERS")
		res[index] = FLD
	
	return res
	
static func randomSymbol():
	return randi_range(0, -1 + len(GlobalVariables.SYMBOLS))

func pulseSymbol():
	if GlobalVariables.PULSE_TILES and not isMechOrSpecial():
		$Symbol.scale = Vector2(1, 1) * lerp(0.1, 0.9, GlobalVariables.VOLUME)
	elif GlobalVariables.PULSE_MECHS and isMechOrSpecial():
		$Symbol.scale = Vector2(1, 1) * lerp(0.1, 0.9, GlobalVariables.VOLUME)
	else:
		$Symbol.scale = Vector2(0.5, 0.5)

func _process(delta):
	pulseSymbol()
	var LAYERS = get_meta("LAYERS")
	var FLUID = get_meta("FLUID")
	var SOURCE = get_meta("SOURCE")
	var END = get_meta("END")
	var SYMBOL = get_meta("SYMBOL")
	
		# Update symbol and fluid sprites
	
	UpdateTileTex()
		
	# Symbol update
	
	var BLOCKER_UPPER = false
	var upppp = getLink(1)
	if upppp != null and upppp.get_meta("SYMBOL") == LASER_BLOCK:
		BLOCKER_UPPER = true
	
	if SYMBOL < 0 and (hasLaser() and BLOCKER_UPPER and !isLaserBlocker()):
		for body in $Area2D.get_overlapping_areas():
			if body.get_parent() is LaserBeam:
				body.get_parent().queue_free()
		set_meta("NO_SYMBOL", false)
		SYMBOL = LASER_BLOCK
		getLink(1).set_meta("SYMBOL", NULL_SYMBOL)
	elif SYMBOL < 0 and (!hasLaser() and !isLaserBlocker()):
		set_meta("NO_SYMBOL", false)
			
	if SYMBOL < 0 and (not END and not get_meta("NO_SYMBOL")):
		var upper = getLink(1)
		if upper == null or upper.NoSymbol():
			SYMBOL = randomSymbol()
		else:
			SYMBOL = upper.get_meta("SYMBOL")
			upper.set_meta("SYMBOL", NULL_SYMBOL)
		
	set_meta("SYMBOL", SYMBOL)
	
	UpdateSymbol()
	
	# Update held sprite
	
	if self in GlobalVariables.SELECTED:
		$Selected.set_visible(true)
		$Selected.set_modulate(GlobalVariables.RAINBOW_COLOR)
	else:
		$Selected.set_visible(false)
		
	IS_HELD = isAlive() and $Button.is_hovered() and get_meta("SYMBOL") >= 0

func _physics_process(delta: float) -> void:
	var LAYERS = get_meta("LAYERS")
	var FLUID = get_meta("FLUID")
	var SOURCE = get_meta("SOURCE")
	var END = get_meta("END")
	var SYMBOL = get_meta("SYMBOL")
	
	if get_meta("NO_SYMBOL"):
		$Button.hide()
	else:
		$Button.show()
	
	# The source of the fluid has FLUID depth 0. Each tile afterwards has FLUID depth of its parent + 1. 
	# This means that if we are not the source then we are 1 + minimum depth of the preceding.
	# Depths of -1 represent non-fluid filled spaces and should be ignored.
	var NEW_LINK = [-1, -1, -1, -1]
	var NEW_LAYER = getLinkedLayers()
	if LAYERS <= 0 or END:
		NEW_LINK = getLinkedFluidDepths()
	
	var SIL = false
	for link in getLinks():
		if link == null:
			continue
		if link.get_meta("SOURCE"):
			SIL = true
			break
	
	if SOURCE:
		LAYERS = 0
		set_meta("LAYERS", LAYERS)
		FLUID = 0
	elif END:
		LAYERS = 0
		set_meta("LAYERS", LAYERS)
		SYMBOL = END_SYMBOL
		FLUID = INF
		for depth in NEW_LINK:
			if depth >= 0 and depth < FLUID:
				FLUID = min(FLUID, depth)
		
		if (FLUID != INF):
			FLUID = 1 + FLUID
		if FLUID == INF:
			FLUID = -1
	
	elif LAYERS > 0 or SYMBOL == BLOCKER_SYMBOL:
		FLUID = -1
	elif (NEW_LINK != LINK_DEPTH) or (NEW_LAYER != LINK_LAYER) or LAYERS <= 0:
		FLUID = INF
		for depth in NEW_LINK:
			if depth >= 0:
				FLUID = min(FLUID, depth)
		
		if (FLUID != INF):
			FLUID = 1 + FLUID
		if FLUID == INF:
			FLUID = -1
	
	set_meta("FLUID", FLUID)
	
	LINK_DEPTH = NEW_LINK
	LINK_LAYER = NEW_LAYER

func UpdateFluid():
	var LAYERS = get_meta("LAYERS")
	var FLUID = get_meta("FLUID")
	var SOURCE = get_meta("SOURCE")
	var END = get_meta("END")
	var SYMBOL = get_meta("SYMBOL")
	
	if LAYERS > 0:
		return
	
	var NEW_LINK = getLinkedFluidDepths()
	FLUID = INF
	for depth in NEW_LINK:
			if depth >= 0:
				FLUID = min(FLUID, depth)
		
	FLUID = 1 + FLUID
	if FLUID == INF:
			FLUID = -1
	
	UpdateTileTex()
	
	set_meta("FLUID", FLUID)
		
func NoSymbol():
	if get_meta("NO_SYMBOL") or get_meta("END"):
		return true
	return false
	
	return false

func Explode():
	if get_meta("INDESTRUCTIBLE"):
		return
	var LAYERS = get_meta("LAYERS")
	var FLUID = get_meta("FLUID")
	var SOURCE = get_meta("SOURCE")
	var END = get_meta("END")
	var SYMBOL = get_meta("SYMBOL")
	set_meta("SYMBOL", NULL_SYMBOL)
	if (LAYERS > 0):
		set_meta("LAYERS", LAYERS - 1)
		GlobalVariables.CELLS_BROKEN += 1
	UpdateFluid()
	UpdateTileTex()

func UpdateTileTex():
	var LAYERS = get_meta("LAYERS")
	var FLUID = get_meta("FLUID")
	var SOURCE = get_meta("SOURCE")
	var END = get_meta("END")
	var SYMBOL = get_meta("SYMBOL")
	
	if FLUID >= 0:
		$TileTex.set_modulate(GlobalVariables.FLUID_COLOR)
	elif LAYERS > 0:
		var col = GlobalVariables.TILE_COLOR / LAYERS
		col.a = 1
		$TileTex.set_modulate(col)
	else:
		$TileTex.set_modulate(GlobalVariables.HOLE_COLOR)
		
func UpdateSymbol():
	var LAYERS = get_meta("LAYERS")
	var FLUID = get_meta("FLUID")
	var SOURCE = get_meta("SOURCE")
	var END = get_meta("END")
	var SYMBOL = get_meta("SYMBOL")
	
	$Symbol.texture = load("res://sprites/Tiles/255.png")
	if END:
		$Symbol.texture = load("res://sprites/Symbols/TRANSPARENT_LIGHTDIAMOND.png")
		$Symbol.set_modulate(GlobalVariables.RAINBOW_COLOR)
	elif not isAlive():
		$Symbol.set_modulate(GlobalVariables.DEAD_COLOR)
		if SYMBOL == BLOCKER_SYMBOL:
			$Symbol.texture = load("res://sprites/TRANSPARENT_FRAME_LIGHT.png")
		elif SYMBOL == LASER_BLOCK:
			$Symbol.texture = load("res://sprites/CIRCLE_64.png")
	elif SYMBOL >= 0:
		$Symbol.set_modulate(GlobalVariables.SYMBOLS[SYMBOL % len(GlobalVariables.SYMBOLS)])
	else:
		$Symbol.set_modulate(GlobalVariables.INVISIBLE)
