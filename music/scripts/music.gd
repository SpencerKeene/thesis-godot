extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var _curr_song = 'Neutral'

const _songs = ['Neutral', 'Happy', 'Sad', 'Fearful', 'Angry']

func change_song(song):
	var new_song = song if song in _songs else 'Neutral'
	if _curr_song == new_song: return
	
	print('Changing song to: ' + new_song)
	$MixingDeskMusic.queue_bar_transition(new_song)
	_curr_song = new_song
