extends Container

var savedScenarios = {}
var list_num = 0
var savesArray = []

func _ready():
	if singleton.isWeb == true:
		savedScenarios = singleton.load_file_as_JSON("user://saved_scenarios.json")
	else:
		savedScenarios = singleton.load_file_as_JSON("res://saved_scenarios.json")
	
	$"../..".connect_arrow_buttons(true)
	$NewScenarioPanel/Buttons/Cancel.connect("pressed", self, "new_panel_cancel_pressed")
	$NewScenarioPanel/Buttons/Create.connect("pressed", self, "new_panel_create_pressed")
	
	add_new_button()
	if savedScenarios != null:
		if savedScenarios["Saves"] != null:
			for save in savedScenarios["Saves"]:
				savesArray.append(save)
			add_saves()
			
			if savedScenarios["Saves"].size() < 4:
				hide_arrows()
		else:
			hide_arrows()


func add_new_button():
	var button = Button.new()
	var label = Label.new()
	button.rect_min_size = Vector2(270,0)
	label.set_text("Add New")
	label.add_font_override("font", load("res://Fonts/Nunito_regular36.font"))
	label.set_anchors_preset(PRESET_CENTER)
	label.margin_left = -77
	label.margin_top = -19
	label.add_color_override("font_color", Color(0.131378,0.739578,0.820312,0.392274))
	button.add_child(label)
	button.connect("pressed", self, "add_new_button_pressed")
	$HBoxContainer.add_child(button)

func add_new_button_pressed():
	$Cover.show()
	$NewScenarioPanel.show()

func new_panel_cancel_pressed():
	$Cover.hide()
	$NewScenarioPanel.hide()
	$NewScenarioPanel/Name.clear()

func new_panel_create_pressed():
	var name = $NewScenarioPanel/Name.get_text()
	if name.length() == 0:
		return
	$Cover.hide()
	$NewScenarioPanel.hide()
	$NewScenarioPanel/Name.clear()
	$"../..".currentScenario = name
	$"../..".scenarioDict = {"Answers": {}, "EditorDetails": {}}
	open_scenario_editor()

func begin_new_scenario():
	open_scenario_editor()

func open_scenario_editor():
	var detail = preload("res://Scenes/Details.tscn").instance()
	$"..".add_child(detail)
	$AnimationPlayer.play("FlyOut")
	detail.get_node("AnimationPlayer").play("FlyIn")
	yield($AnimationPlayer, "animation_finished")
	show_arrows()
	$"..".add_child(detail)
	$"../../CanvasLayer/TextureProgress".show()
	$"../../CanvasLayer/Menu".show()
	$"../..".connect_arrow_buttons(false)
	$"../..".set_to_start()
	$"../../CanvasLayer/Right".set_disabled(false)
##	$"../../CanvasLayer/Left".set_disabled(false)
	queue_free()

func add_saves():
	var RANGE
	var start
	if list_num == 1:
		start = 3
		RANGE = 7
	elif list_num > 1:
		start += 4
		RANGE += 4
	else:
		start = 0
		RANGE = 3
		set_arrow_disabled(1)
	
	if RANGE > savesArray.size():
		RANGE = savesArray.size()
		set_arrow_disabled(0)
		
		
	for i in range(start, RANGE):
#	for save in savedScenarios["Saves"]:
		var node = load("res://Scenes/savedScenarioButton.tscn").instance()
		node.set_name(savesArray[i])
		node.get_node("Name").set_text(savesArray[i])
		node.get_node("Sprite").set_frame(savedScenarios["Saves"][savesArray[i]]["ScenarioDetails"]["Sprite"])
		node.get_node("Topic").set_text(savedScenarios["Saves"][savesArray[i]]["topic"])
		node.get_node("Difficulty").set_text(savedScenarios["Saves"][savesArray[i]]["ScenarioDetails"]["Difficulty"])
		node.connect("pressed", self, "load_selected_pressed", [node])
		$HBoxContainer.add_child(node)

func load_selected_pressed(node):
	var scenario = node.get_name()
	if savedScenarios["Saves"][scenario]["EditorDetails"].has("StoryData"):
		savedScenarios["Saves"][scenario]["EditorDetails"]["StoryData"] = node_JSON_to_vector2(savedScenarios["Saves"][scenario]["EditorDetails"]["StoryData"])
	$"../..".currentScenario = scenario
	$"../..".scenarioDict = savedScenarios["Saves"][scenario]
	open_scenario_editor()

func scroll_loads(button):
#	if load_list > 0:
#		load_list += 4
#	else:
#		load_list += 3
	if button.get_name() == "Right":
		list_num += 1
		if button.get_node("../Left").is_disabled():
			button.get_node("../Left").set_disabled(false)
	else:
		list_num -= 1
		if button.get_node("../Right").is_disabled():
			button.get_node("../Right").set_disabled(false)
	singleton.clear_container($HBoxContainer)
	
	if list_num == 0:
		add_new_button()
	
	add_saves()

func set_arrow_disabled(arrow):
	if arrow == 0:
		$"../../CanvasLayer/Right".set_disabled(true)
	elif arrow == 1:
		$"../../CanvasLayer/Left".set_disabled(true)

func hide_arrows():
	$"../../CanvasLayer/Right".hide()
	$"../../CanvasLayer/Left".hide()

func show_arrows():
	$"../../CanvasLayer/Right".show()
	$"../../CanvasLayer/Left".show()
#func node_data_to_JSON():
#	var jsonNodeData = str2var(var2str(storyNodeData))
#	for story in jsonNodeData:
#		for node in jsonNodeData[story]:
#			if node != "Start":
#				jsonNodeData[story][node]["position"] = [jsonNodeData[story][node]["position"].x, jsonNodeData[story][node]["position"].y]
#			for connection in jsonNodeData[story][node]["connections"]:
#				for i in range(0, jsonNodeData[story][node]["connections"][connection].size()):
#					if typeof(jsonNodeData[story][node]["connections"][connection][i]) == TYPE_VECTOR2:
#						jsonNodeData[story][node]["connections"][connection][i] = [jsonNodeData[story][node]["connections"][connection][i].x, jsonNodeData[story][node]["connections"][connection][i].y]
#	return jsonNodeData

func node_JSON_to_vector2(jsonData):
	var dict = jsonData
	for story in dict:
		for node in dict[story]:
			if node != "Start":
				dict[story][node]["position"] = Vector2(dict[story][node]["position"][0], dict[story][node]["position"][1])
			for connection in dict[story][node]["connections"]:
				for i in range(0, dict[story][node]["connections"][connection].size()):
					if typeof(dict[story][node]["connections"][connection][i]) == TYPE_ARRAY:
						dict[story][node]["connections"][connection][i] = Vector2(dict[story][node]["connections"][connection][i][0], dict[story][node]["connections"][connection][i][1])
	return dict