extends Node2D

var bedDifferentials = []
var bedPrescriptions = {"OnceOnly": {}, "Regular": {}, "AsRequired": {}, "Infusion": {}, "Oxygen": {}}
var bedInvestigations = {"Complete": [], "Pending": {}}
var playerInfo = {"Forename": "Sarah", "Surname": "Button", "Inventory": []}
var bedProcedures = null
var bedHistory = null
var bedContacts = null
var bedStoryArray = [0, 0, 0]
var calls = {}
var bedBleeps = {}
var bedNotes = null


func _ready():
#	$GUI/Button.connect("pressed", singleton, "test_java")
	
	var player = get_node("playerNode/Player")
	var interactables = get_tree().get_nodes_in_group("Interactable")
	for interactable in interactables:
		var area2d = interactable.get_node("Area2D")
		area2d.connect("body_entered", player, "_on_area2d_body_enter", [interactable])
		area2d.connect("body_exited", player, "_on_area2d_body_exit", [interactable])
    
	
	
	var timer = Timer.new()
	timer.connect("timeout", self, "one_second")
	timer.start()
	timer.set_name("Timer")
	add_child(timer)

func one_second():
	if bedBleeps.size() > 0:
		for bleep in bedBleeps:
			if bedBleeps[bleep][0] >= 1:
				bedBleeps[bleep][0] -= 1
			else:
				bleep_returned(bleep, bedBleeps[bleep][1])
				bedBleeps.erase(bleep)

func bleep_returned(bleep, phone):
	var text = bleep + " is calling " + phone + " phone"
#	play_animation("Emergency Department Phone 1")
	if calls.has(phone) == false:
		calls[phone] = bleep
	print(calls)
	add_notification(text)

func add_notification(text, colour = 0):
	if get_node("GUI").has_node("Notifications"):
		get_node("GUI/Notifications").add_label(text, colour)
	else:
		var node = preload("res://Scenes/playerUpdateScreen.tscn").instance()
		get_node("GUI").add_child(node)
		get_node("GUI/Notifications").add_label(text, colour)