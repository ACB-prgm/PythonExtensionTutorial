extends Node2D


var DIR = OS.get_executable_path().get_base_dir()
var interpreter_path = DIR.plus_file("PythonFiles/venv/bin/python3.10")
var script_path = DIR.plus_file("PythonFiles/notify.py")


func _ready():
	if !OS.has_feature("standalone"): # if NOT exported version
		interpreter_path = ProjectSettings.globalize_path("res://PythonFiles/venv/bin/python3.10")
		script_path = ProjectSettings.globalize_path("res://PythonFiles/notify.py")
	
	notify("Godot", "Notify", "Godot is awesome!")

func notify(title="", subtitle="", body=""):
	var err = OS.execute(interpreter_path, [script_path, title, subtitle, body])
	print(err)

