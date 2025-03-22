extends Node

# Audio volume for pulsing objects

var VOLUME = 0
var VOLZEROTIMER = 0
var VOL_RUN = []
var MAX_VOL_RUN = 16

var PULSE_TILES = false # Do we pulse the tiles you link together (i.e. not mechanisms and other special tiles)

# Dimensions and constants 

var TL = Vector2(-10000, -10000)
var BR = Vector2(10000, 10000)

var RAINBOW = 0
var RAINBOW_COLOR = Color(0.5, 0.5, 0.5, 1)

var CELL_SIZE = 64

# Aesthetics

var FLUID_COLOR = Color(0.75, 1, 1, 1)
var TILE_COLOR = Color(1, 1, 1, 1)
var HOLE_COLOR = Color(0.1, 0.1, 0.1, 1)
var INVISIBLE = Color(0, 0, 0, 0)

var SYMBOLS = [Color.RED, Color.GREEN, Color.CYAN, Color.BLUE]
var DEAD_COLOR = Color(1, 1, 1, 0) * 0.25 + Color(0, 0, 0, 1)

var HOLDING = false
var SELECTED = []
var HELD_SYMBOL = -1

var MIN_HOLD = 3
var MIN_EXP = 6

# Sources and Endpoints

var SOURCES = []
var ENDS = []

var DISTS_ENDS = {} # Map each tile to a depth relative to and endpoint
var DISTS_SOURCES = {} # Map each fluid tile to a depth relative to start point.

var CAM_INFO = "NULL"

# TIMING/LOGISTICS

var START_TIME = 69
var END_TIME = 420
var CELLS_BROKEN = 0
var FLUID_TILES = 0
var LONGEST_RUN = 0

# Levels

var LEVELS = ["INTRODUCTION", "TREK", "LASERS", "EXPANSION", "VERTICALITY", "CONCURRENT", "BARRIER", "TIDE"]
var BG = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TL = get_viewport().size * -1
	BR = get_viewport().size * 2
	print(TL, BR)

func CHECKQUIT():
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_X):
		get_tree().quit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	RAINBOW = (RAINBOW + 1) % (256 * 6)
	RAINBOW_COLOR = GlobalVariables.FullHue(GlobalVariables.RAINBOW)
	
	var FLUID_SAT = 0.2;
	FLUID_COLOR = GlobalVariables.FullHue(GlobalVariables.RAINBOW + 3 * 256) * FLUID_SAT + Color(1, 1, 1, 1) * (1 - FLUID_SAT)
	
	var volume = (AudioServer.get_bus_peak_volume_left_db(0,0) + AudioServer.get_bus_peak_volume_right_db(0,0)) / 2
	if (volume == -200):
		VOLZEROTIMER += 1
	else:
		VOLZEROTIMER = 0
	
	if VOLZEROTIMER >= 30:
		volume = 0
		
	# UPDATE THE VOLUME SIGMOID SO THAT THE PULSING OBJECTS PULSE VIBRANTLY
		
	VOL_RUN.append(volume)
	while len(VOL_RUN) > MAX_VOL_RUN:
		VOL_RUN.pop_front()
		
	var AVG = 0
	for vol in VOL_RUN:
		AVG += vol / len(VOL_RUN)
		
	var SD = 0
	for vol in VOL_RUN:
		SD += (vol - AVG) * (vol - AVG) / len(VOL_RUN)
		
	SD = sqrt(SD)
	
	# volume = specanal.get_magnitude_for_frequency_range(0, 10000).length()
	
	var normalized = truesigmoid((volume - AVG), 0.25 / SD)
	if (normalized < 0):
		normalized = 0
	elif (normalized > 1):
		normalized = 1
	# print(volume, " ... ", normalized)
	VOLUME = normalized
	CHECKQUIT()

# MATH / UTIL FUNCTIONS

func truesigmoid(x, s): # Sigmoid with dy/dx = s @x = 0
	var res = 1 + exp(-1 * s * x)
	return (1.0 / res)

func sigmoid(x, s): # Sigmoid with dy/dx = s @x = 0
	var res = 1 + exp(-2 * s * x)
	return (2.0 / res) - 1
	
func rotate(disp: Vector2, step):
	if (step == 1):
		return Vector2(-1 * disp.y, disp.x)
	if (step == 2):
		return Vector2(-1 * disp.x, -1 * disp.y)
	if (step == 3):
		return Vector2(disp.y, -1 * disp.x)
	else:
		return Vector2(disp.x, disp.y)
		
func clamp(x, L, H):
	if x < L:
		x = L
	elif x > H:
		x = H
		
	return x

func FullHue(colorIndex):
	colorIndex = colorIndex % (6 * 256)
	
	var index = int(colorIndex / 256)
	var val = (colorIndex / 256.0) - index
	
	var red = 0
	var green = 0
	var blue = 0
	
	if (index == 0):
		red = 1
		blue = 0
		green = val
	elif (index == 1):
		red = 1 - val
		green = 1
		blue = 0
	elif (index == 2):
		red = 0
		green = 1
		blue = val
	elif (index == 3):
		red = 0
		green = 1 - val
		blue = 1
	elif (index == 4):
		red = val
		green = 0
		blue = 1
	elif (index == 5):
		red = 1
		green = 0
		blue = 1 - val
	else:
		red = 1
		green = 1
		blue = 1
	
	return Color(red, green, blue, 1)
