extends Node

signal closed
signal item_used 

var bedProcedures 
onready var collectablesDict = singleton.load_file_as_JSON("res://JSON_files/Collectables.json")

func _ready():
	add_inventory()
	set_process_unhandled_key_input(true)
	bedProcedures = $"/root/MainFrame".scenarioDict["Answers"]["Procedures"]

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_cancel") && get_node("../../playerNode/Player").canCancel == true:
		close_item_screen()

func add_inventory():
	var container = $Patch9Frame/ScrollContainer/VBoxContainer
	for item in $"../..".playerInfo["Inventory"]:
		var button = preload("res://Scenes/InvestigationButton.tscn").instance()
		button.set_name(item)
		button.get_node("Label").set_text(item)
		button.get_node("Order/Label").set_text("Use")
		button.get_node("Order").connect("pressed", self, "use_item_pressed", [button.get_name()])
		container.add_child(button)
		

func use_item_pressed(item):
	emit_signal("item_used")
	$Patch9Frame/ScrollContainer.hide()
	$Patch9Frame/Label.hide()
	$Patch9Frame/RichTextLabel.show()
	var text = ""
	if bedProcedures.has(item):
		$Patch9Frame/RichTextLabel.bbcode_text = bedProcedures[item]
	else:
		$Patch9Frame/RichTextLabel.bbcode_text = collectablesDict[item]["Detail"]
	if $"../..".bedProcedures == null:
		$"../..".bedProcedures = [item]
	else:
		$"../..".bedProcedures.append(item)
	$"../..".playerInfo["Inventory"].erase(item)

func close_item_screen():
	emit_signal("closed")
	get_node("../../playerNode/Player").allow_movement()
	get_node("../../playerNode/Player").zoom_out()
	get_node("../../playerNode/Player").menuOpen = null
	$Patch9Frame.hide()
	get_node("../../GUI/notes").close_notes()
	yield(get_node("../../playerNode/Player"), "zoomed_out")
	get_node("../../playerNode/Player").allow_interaction()
	queue_free()
	$"/root/MainFrame/Current/TestScreen".use_item = false
