extends Node


var frames := 0
var other := "LIKES"


func _ready():
	print("%s ARE COOL TOO" % other)


func physics_process(delta):
	frames += 1
	if frames == 10:
		frames = 0
		subscribe()


func subscribe() -> void:
	print("SUBSCRIBE!")

