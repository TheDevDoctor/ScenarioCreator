extends Node

onready var player = $"../../playerNode/Player"
onready var dialogueParser = $"../../DialogueParser"

func _ready():
	$Patch9Frame/VBoxContainer/Yes.connect("pressed", self, "finished_ix_pressed")
	$Patch9Frame/VBoxContainer/No.connect("pressed", self, "not_fin_ix_pressed")

func finished_ix_pressed():
	$Patch9Frame.hide()
	player.zoom_in()
	yield(player, "zoomed_in")
	$"../..".bedStoryArray[0] = 2
	dialogueParser.init_patient_dialogue(player.target)
#	player.open_notes()
	close()


func not_fin_ix_pressed():
	$Patch9Frame.hide()
	player.zoom_in()
	yield(player, "zoomed_in")
	dialogueParser.init_patient_dialogue(player.target)
#	player.open_notes()
	close()

func close():
	queue_free()