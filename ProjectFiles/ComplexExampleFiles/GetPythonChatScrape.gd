extends Node

const UDP_IP = "127.0.0.1"
const UDP_PORT = 4243

var server := UDPServer.new()
var is_broadcasting := false
var process_pids := []
var LiveStream_URL := "https://www.youtube.com/watch?v="

onready var YouTubeScrape_py = ProjectSettings.globalize_path("res://PythonFiles/YouTubeScrape.py")
onready var interpreter_path = ProjectSettings.globalize_path("res://PythonFiles/venv/bin/python")

signal chat_packet_recieved(chat_packet)


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if is_broadcasting:
			kill_processes()
		get_tree().quit() # default behavior


func _ready():
	set_process(false)
	YoutTubeApi.connect("BroadcastID_recieved", self, "_on_YoutTubeApi_BroadcastID_recieved")


func _process(_delta):
# warning-ignore:return_value_discarded
	server.poll()
	if server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet().get_string_from_utf8()
		packet = JSON.parse(packet).result
		
		if packet is Array:
			var py_type = packet.pop_front()
			
			match py_type:
				"PIDs":
					process_pids.append_array(packet)
				"CHAT":
					emit_signal("chat_packet_recieved", packet)
				"KEY_INPUT":
					print(packet)
		else:
			push_error("ERROR : PYTHON TYPE RECIEVED IS NOT TYPE ARRAY")


func start_listening():
# warning-ignore:return_value_discarded
	server.listen(UDP_PORT)
	set_process(true)
	
	is_broadcasting = true


func stop_listening():
	server.stop()
	set_process(false)
	
	is_broadcasting = false


func start_scraping():
	var PID = OS.execute(interpreter_path, [YouTubeScrape_py, LiveStream_URL], false)
	process_pids.append(float(PID))


func _on_YoutTubeApi_BroadcastID_recieved(success):
	if success:
		LiveStream_URL += YoutTubeApi.BroadcastID
		start_listening()
		start_scraping()

#func start_keyboard_input():
#	var PID = OS.execute("sudo", [interpreter_path, global_path_to_dir + "/KeyboardInput.py"], false)
## warning-ignore:return_value_discarded
#	OS.execute(str(PID), ["INPUT PASSWORD HERE"])
#	process_pids.append(PID)


func kill_processes():
	for pid in process_pids:
# warning-ignore:return_value_discarded
		OS.kill(pid)
