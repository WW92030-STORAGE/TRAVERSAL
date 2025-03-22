class_name BGElement
extends Node2D

var MVT = Vector2(1, 0)
var DIM = Vector2(1000, 1000)
var OFFSCREEN = 2.5
var IMG_SIZE = 1024

var ROWS = 4
var COLS = 4

func _ready():
	MVT = MVT.rotated(randf() * 4 * PI)
	DIM = get_viewport().size
	
	for obj in get_children():
		obj.texture = get_meta("IMAGE_TEXTURE")

func _physics_process(delta: float) -> void:
	for obj in get_children():
		obj.texture = get_meta("IMAGE_TEXTURE")
		obj.position += MVT
		if (obj.position.x > OFFSCREEN * IMG_SIZE):
			obj.position.x -= IMG_SIZE * COLS
		if (obj.position.x < (1 - OFFSCREEN) * IMG_SIZE):
			obj.position.x += IMG_SIZE * COLS
		if (obj.position.y > OFFSCREEN * IMG_SIZE):
			obj.position.y -= IMG_SIZE * ROWS
		if (obj.position.y < (1 - OFFSCREEN) * IMG_SIZE):
			obj.position.y += IMG_SIZE * ROWS
