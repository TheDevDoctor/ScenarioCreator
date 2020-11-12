extends Node

signal vitals_closed

func _ready():
	pass

func set_values(bed):
	var vitals = get_node("/root/MainFrame").scenarioDict["Vitals"]
	for vital in vitals:
		if vital == "BP":
			get_node("Patch9Frame/HBoxContainer/Labels/" + vital).set_text(str(vitals[vital]["Systolic"]) + "/" +str(vitals[vital]["Diastolic"]))
		else:
			get_node("Patch9Frame/HBoxContainer/Labels/" + vital).set_text(str(vitals[vital]))

func close_menu():
	queue_free()
	$"../../playerNode/Player".allow_movement()
	$"../../playerNode/Player".allow_interaction()
	$"../../playerNode/Player".menuOpen = null
	$"../../GUI/notes".close_notes()