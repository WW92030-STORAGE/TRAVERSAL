class_name LevelSelection
extends MarginContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for button in get_tree().get_nodes_in_group("LEVEL_BUTTON"):
		button.pressed.connect(_on_button_pressed.bind(button))
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var hovered = false
	for button in get_tree().get_nodes_in_group("LEVEL_BUTTON"):
		hovered = hovered or hover(button)
	if not hovered:
		$VBoxContainer/LEVEL_NAME.text = "SELECT LEVEL"


func _on_quit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_button_pressed(button) -> void:
	print("PRESSED")
	print(button.name)
	
	# Set the BG if the button demands it
	GlobalVariables.BG = ""
	if button.get_meta("RETVAL") != {}:
		GlobalVariables.BG = button.get_meta("RETVAL")["bg"]
		print(GlobalVariables.BG)
	
	
	# Enter level
	
	get_tree().change_scene_to_file("res://levels/" + button.name.substr(8) + ".tscn")


func _on_button_mouse_entered(button) -> void:
	var INDEX = int(button.name.substr(8)) - 1
	print("ENTERED", INDEX)
	if INDEX >= len(GlobalVariables.LEVELS):
		$VBoxContainer/LEVEL_NAME.text = "NULL"
		return
	# Set the header name if the button demands it
	if button.get_meta("RETVAL") == {}:
		$VBoxContainer/LEVEL_NAME.text = str(INDEX + 1) + "-" + GlobalVariables.LEVELS[INDEX]
	else:
		$VBoxContainer/LEVEL_NAME.text = str(INDEX + 1) + "-" + button.get_meta("RETVAL")["name"]
	
func hover(button):
	if not button.is_hovered():
		return 0
	var INDEX = int(button.name.substr(8)) - 1
	# print("HOVERING ", INDEX)
	if INDEX >= len(GlobalVariables.LEVELS):
		$VBoxContainer/LEVEL_NAME.text = "NULL"
		return 1
	if "name" not in button.get_meta("RETVAL"):
		$VBoxContainer/LEVEL_NAME.text = str(INDEX + 1) + "-" + GlobalVariables.LEVELS[INDEX]
	else:
		$VBoxContainer/LEVEL_NAME.text = str(INDEX + 1) + "-" + button.get_meta("RETVAL")["name"]
	
	return 1
	


func _on_button_mouse_exited() -> void:
	$VBoxContainer/LEVEL_NAME.text = "SELECT LEVEL"
	pass # Replace with function body.
