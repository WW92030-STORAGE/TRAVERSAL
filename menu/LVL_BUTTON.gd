class_name LevelButton
extends Button

func pad(s, N):
	while (len(s) < N):
		s = "0" + s
	return s

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = pad(str(name.substr(8)), 2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var args = get_meta("args")


func _on_mouse_entered() -> void:
	var args = get_meta("ARGS")
	set_meta("RETVAL", {})
	var RETVAL = {}
	
	print("MOUSE ENTERED THIS BUTTON", name)
	print("ARGS:", get_meta("ARGS"))
		
	set_meta("RETVAL", RETVAL)


func _on_mouse_exited() -> void:
	var args = get_meta("ARGS")
