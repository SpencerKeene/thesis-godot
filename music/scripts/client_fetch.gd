extends Node

var project_path = ProjectSettings.globalize_path("res://")

# Define Parameters
const HOST: String = "127.0.0.1"
const PORT: int = 34012
const RECONNECT_TIMEOUT: float = 1.0
const EMOTION_SERVER_PATH: String = 'D:/GitHub/Emotion-detection/src'

const Client = preload("./client.gd")
var _client: Client = Client.new()

var py_server_pid = null

# used for testing
var datetime_of_game_start = Time.get_datetime_string_from_datetime_dict(OS.get_datetime(), false).replace(":", "-")
var times_dir = "request_times"
var times_filename = "request_times_" + datetime_of_game_start + ".txt"
var times_path = "user://" + times_dir + "/" + times_filename

func _save_request_time(timestamp: int, request_time: int, emotion: String):
	# function used in testing to save time taken to make a request and receive a response
	var times = File.new()
	if times.open(times_path, File.READ_WRITE) != 0:
		print("Error opening file " + times_path)
		return
	times.seek_end()
	times.store_csv_line([str(timestamp), str(request_time), emotion])
	times.close()
	print("Saved time for request: " + str(request_time))

func _create_request_times_file():
	var dir = Directory.new()
	dir.open("user://")
	if not dir.dir_exists(times_dir):
		dir.make_dir(times_dir)
		print("Created directory " + times_dir)
	else:
		print("Directory " + times_dir + " already exists")
	
	var times = File.new()
	if times.open(times_path, File.WRITE) != 0:
		print("Error creating file " + times_path)
		return
	times.store_csv_line(['timestamp', 'request_time', 'emotion'])
	times.close()
	print("Created file " + times_filename)

func _ready() -> void:
	_create_request_times_file()
	
	_client.connect("connected", self, "_handle_client_connected")
	_client.connect("disconnected", self, "_handle_client_disconnected")
	_client.connect("error", self, "_handle_client_error")
	_client.connect("data", self, "_handle_client_data")
	add_child(_client)
	_client.connect_to_host(HOST, PORT)
	
	# Start emotion detection program
	#var py_server_path = project_path + EMOTION_SERVER_PATH
	#py_server_pid = OS.execute("python3", [py_server_path], false, [], false, true)
	#print('py_server_path: ', py_server_path)
	#print('py_server_pid: ', py_server_pid)

func _connect_after_timeout(timeout: float) -> void:
	yield(get_tree().create_timer(timeout), "timeout") # Delay for timeout
	_client.connect_to_host(HOST, PORT)

func _handle_client_connected() -> void:
	print("Client connected to server.")
	pass

func _handle_client_data(data: PoolByteArray) -> void:
	var newState = data.get_string_from_utf8()
	print("Fetched emotion: ", newState)
	$Music.change_song(newState)
	
	var now = OS.get_ticks_usec()
	var total_time = now - _client.connection_start
	_save_request_time(now / 1000, total_time, newState)
	
	var message: PoolByteArray = [97, 99, 107] # Bytes for "ack" in ASCII
	_client.send(message)

func _handle_client_disconnected() -> void:
	print("Client disconnected from server.")
	_connect_after_timeout(RECONNECT_TIMEOUT) # Try to reconnect after 1 second

func _handle_client_error() -> void:
	print("Client error.")
	_connect_after_timeout(RECONNECT_TIMEOUT) # Try to reconnect after 1 second


func _on_Node2D_tree_exiting():
	if py_server_pid != null: 
		print('shutting down ', py_server_pid)
		OS.kill(py_server_pid)
