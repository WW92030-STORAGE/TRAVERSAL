extends Camera2D

func setup():
	if get_meta("MUSIC") != null:
		$AudioStreamPlayer2D.stream = (get_meta("MUSIC"))
		print("BGM = ", get_meta("MUSIC"))
		$AudioStreamPlayer2D.play()

func _ready():
	setup()


func _on_audio_stream_player_2d_finished() -> void:
	setup()
