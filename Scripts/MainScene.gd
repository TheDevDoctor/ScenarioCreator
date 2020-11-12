extends Control

onready var progressBar = $CanvasLayer/TextureProgress
var screens = ["Details", "DialogueCreator", "History", "Examinations", "DialogueCreator", "Investigations", "DialogueCreator", "Management", "Explanation", "TestScenario"]
var progressPositions = [27, 135, 241, 349, 456, 564, 671, 779, 886, 1000]
var currentScreen = 0
var progress = false
var progressTo
var currentScenario = "new_save"

var scenarioDict = {"Answers": {}, "EditorDetails": {}}
var testScenarioDict = {}

func _ready():
	$CanvasLayer/TextureProgress.value = 27
	$CanvasLayer/Menu/HBoxContainer/Save.connect("pressed", self, "save_pressed")
	$CanvasLayer/Menu/HBoxContainer/Exit.connect("pressed", self, "exit_pressed")
	$CanvasLayer/HangOn/Buttons/No.connect("pressed", self, "no_to_save")
	$CanvasLayer/HangOn/Buttons/Yes.connect("pressed", self, "yes_to_save")
	_process(false)
	
	connect_help_nodes($Current.get_child(0))
	connect_arrow_buttons(true)
	testScenarioDict = singleton.load_file_as_JSON("res://Migraine.json")
	
	for button in $CanvasLayer/TextureProgress/Buttons.get_children():
		button.connect("mouse_entered", self, "texture_button_mouse_entered", [button])
		button.connect("mouse_exited", self, "texture_button_mouse_exited", [button])
		button.connect("pressed", self, "texture_button_pressed", [button])


func _process(delta):
	if progress == true:
		if progressBar.value == progressTo:
			progress = false
			_process(false)
		elif progressBar.value < progressTo:
			if (progressTo - progressBar.value) > 200:
				progressBar.value += 10
			elif (progressTo - progressBar.value) > 50:
				progressBar.value += 5
			elif (progressTo - progressBar.value) > 25:
				progressBar.value += 3
			elif (progressTo - progressBar.value) > 10:
				progressBar.value += 2
			else:
				progressBar.value += 1
		
		elif progressBar.value > progressTo:
			if (progressBar.value - progressTo) > 200:
				progressBar.value -= 10
			elif (progressBar.value - progressTo) > 50:
				progressBar.value -= 5
			elif (progressBar.value - progressTo) > 25:
				progressBar.value -= 3
			elif (progressBar.value - progressTo) > 10:
				progressBar.value -= 2
			else:
				progressBar.value -= 1

func set_to_start():
	$CanvasLayer/TextureProgress.value = 27
	currentScreen = 0

func connect_arrow_buttons(LOAD_SCREEN):
	print("connecting arrows")
	if LOAD_SCREEN:
		$CanvasLayer/Left.disconnect("pressed", self, "change_screen_arrow_pressed")
		$CanvasLayer/Right.disconnect("pressed", self, "change_screen_arrow_pressed")
		$CanvasLayer/Left.connect("pressed", $Current/LoadList, "scroll_loads", [$CanvasLayer/Left])
		$CanvasLayer/Right.connect("pressed", $Current/LoadList, "scroll_loads", [$CanvasLayer/Right])
	else:
		$CanvasLayer/Left.disconnect("pressed", $Current/LoadList, "scroll_loads")
		$CanvasLayer/Right.disconnect("pressed", $Current/LoadList, "scroll_loads")
		$CanvasLayer/Left.connect("pressed", self, "change_screen_arrow_pressed", [$CanvasLayer/Left])
		$CanvasLayer/Right.connect("pressed", self, "change_screen_arrow_pressed", [$CanvasLayer/Right])

func change_screen_arrow_pressed(button):
	print(currentScreen)
	$CanvasLayer/Left.set_disabled(true)
	$CanvasLayer/Right.set_disabled(true)
	save_screen_data()
	if button.get_name() == "Left":
		if currentScreen > 0:
			currentScreen -= 1
			set_screen(1)
	if button.get_name() == "Right":
		if currentScreen < 9:
			currentScreen += 1
			set_screen(0)

func set_screen(direction):
	var node = load("res://Scenes/" + screens[currentScreen] + ".tscn").instance()
	var previous = $Current.get_child(0)
	$Current.add_child(node)
	progressTo = progressPositions[currentScreen]
	progress = true
	_process(false)
	if direction == 0:
		previous.get_node("AnimationPlayer").play("FlyOut")
		node.get_node("AnimationPlayer").play("FlyIn")
		yield(previous.get_node("AnimationPlayer"), "animation_finished")
		connect_help_nodes($Current.get_child(1))
		previous.queue_free()
	elif direction == 1:
		previous.get_node("AnimationPlayer").play_backwards("FlyIn")
		node.get_node("AnimationPlayer").play_backwards("FlyOut")
		yield(previous.get_node("AnimationPlayer"), "animation_finished")
		connect_help_nodes($Current.get_child(1))
		previous.queue_free()
	if currentScreen != 0:
		$CanvasLayer/Left.set_disabled(false)
	if currentScreen != 10:
		$CanvasLayer/Right.set_disabled(false)

func save_screen_data():
	if currentScreen == 0:
		save_details_to_dict()
	elif currentScreen == 1:
		save_story_to_dict()
	elif currentScreen == 2:
		save_history_to_dict()
	elif currentScreen == 3:
		save_examinations_to_dict()
	elif currentScreen == 4:
		save_story_to_dict()
	elif currentScreen == 5:
		save_investigations_to_dict()
	elif currentScreen == 6:
		save_story_to_dict()
	elif currentScreen == 7:
		save_management_to_dict()
	elif currentScreen == 8:
		save_explanation_to_dict()


#save the details from the details screen when screen changed. 
func save_details_to_dict():
	#get scenario details and add to dict. 
	scenarioDict["topic"] = $Current/Details/ScenarioDetails/VBoxContainer/Specialty.get_item_text($Current/Details/ScenarioDetails/VBoxContainer/Specialty.get_selected())
	scenarioDict["description"] = $Current/Details/WebsiteInfo/TextEdit.get_text()
	scenarioDict["ScenarioDetails"] = {}
	scenarioDict["ScenarioDetails"]["Sprite"] = $Current/Details/PatientDetails/Sprite.get_frame()
	var container = $Current/Details/ScenarioDetails/VBoxContainer
	for i in range(0, container.get_child_count()):
		scenarioDict["ScenarioDetails"][container.get_child(i).get_name()] = container.get_child(i).get_item_text(container.get_child(i).get_selected())
	
	#get patient details details and add to dict. 
	scenarioDict["PatientDetails"] = {}
	container = $Current/Details/PatientDetails/VBoxContainer
	for i in range(0, container.get_child_count()):
		if container.get_child(i).is_class("OptionButton"): 
			scenarioDict["PatientDetails"][container.get_child(i).get_name()] = container.get_child(i).get_item_text(container.get_child(i).get_selected())
		else:
			scenarioDict["PatientDetails"][container.get_child(i).get_name()] = container.get_child(i).get_text()
	
	#get vitals details and add to dict.
	scenarioDict["Vitals"] = {}
	container = $Current/Details/Vitals/VBoxContainer
	for i in range(0, container.get_child_count()):
		if container.get_child(i).get_name() == "BP":
			scenarioDict["Vitals"]["BP"] = {"Systolic": container.get_child(i).get_node("Systolic").get_text(), "Diastolic": container.get_child(i).get_node("Diastolic").get_text()}
		else:
			scenarioDict["Vitals"][container.get_child(i).get_name()] = container.get_child(i).get_text()
	
	

func save_story_to_dict():
	var dialogueCreator = $Current.get_child(0)
	dialogueCreator.make_story_json()
	if scenarioDict.has("Story"):
		scenarioDict["Story"][dialogueCreator.currentStory] = dialogueCreator.storyJSON
	else:
		scenarioDict["Story"] = {}
		scenarioDict["Story"][dialogueCreator.currentStory] = dialogueCreator.storyJSON
	
	if scenarioDict["EditorDetails"].has("StoryData"):
		scenarioDict["EditorDetails"]["StoryData"][dialogueCreator.currentStory] = dialogueCreator.storyDict
	else:
		scenarioDict["EditorDetails"]["StoryData"] = {}
		scenarioDict["EditorDetails"]["StoryData"][dialogueCreator.currentStory] = dialogueCreator.storyDict

func save_history_to_dict():
	var history = $Current.get_child(0)
	history.save_history_data()
	scenarioDict["History"] = history.responseDict
	scenarioDict["Answers"]["History"] = history.correctDict

func save_examinations_to_dict():
	var examinations = $Current.get_child(0)
	scenarioDict["Answers"]["Examinations"] = examinations.correctExams
	scenarioDict["Examinations"] = examinations.get_node("Container/NinePatchRect/Patch9Frame").examChange

func save_investigations_to_dict():
	var investigations = $Current.get_child(0)
	scenarioDict["Answers"]["Investigations"] = investigations.correctIx
	scenarioDict["Investigations"] = investigations.ixChange

func save_management_to_dict():
	var management = $Current.get_child(0)
	scenarioDict["Answers"]["Prescriptions"] = management.prescriptionDict
	scenarioDict["Answers"]["Contact"] = management.calls
	scenarioDict["Answers"]["Procedures"] = management.proceduresChange

func save_explanation_to_dict():
	var explanation = $Current.get_child(0)
	scenarioDict["Explanation"] = explanation.get_node("Container/Explanation").get_text()

func connect_help_nodes(parent):
	if parent.has_node("HelpNodes"):
		for node in parent.get_node("HelpNodes").get_children():
			node.connect("mouse_entered", self, "help_mouse_enter", [node])
			node.connect("mouse_exited", self, "help_mouse_exit", [node])

func help_mouse_enter(node):
	print("enter")
	node.set_texture(preload("res://Graphics/IHover.png"))

func help_mouse_exit(node):
	node.set_texture(preload("res://Graphics/INormal.png"))


func texture_button_mouse_entered(button):
	button.set_self_modulate(Color(0.04483,0.077564,0.882812))
func texture_button_mouse_exited(button):
	button.set_self_modulate(Color(1,1,1,0.003922))

func texture_button_pressed(button):
	var newScreen = int(button.get_name())
	var direction
	if currentScreen == newScreen:
		return
	elif currentScreen < newScreen:
		direction = 0
	else:
		direction = 1
	save_screen_data()
	$CanvasLayer/Left.set_disabled(true)
	$CanvasLayer/Right.set_disabled(true)
	currentScreen = newScreen
	set_screen(direction)

func exit_pressed():
	$CanvasLayer/Cover.show()
	$CanvasLayer/HangOn.show()

func no_to_save():
	$CanvasLayer/Cover.hide()
	$CanvasLayer/HangOn.hide()
	exit_to_load_screen()

func yes_to_save():
	$CanvasLayer/Cover.hide()
	$CanvasLayer/HangOn.hide()
	save_current_scenario()
	exit_to_load_screen()

func save_pressed():
	save_current_scenario()

func exit_to_load_screen():
	var node = load("res://Scenes/LoadList.tscn").instance()
	var previous = $Current.get_child(0)
	$Current.add_child(node)
	connect_arrow_buttons(true)
	$CanvasLayer/TextureProgress.hide()
	$CanvasLayer/Menu.hide()
	previous.get_node("AnimationPlayer").play_backwards("FlyIn")
	node.get_node("AnimationPlayer").play_backwards("FlyOut")
	yield(previous.get_node("AnimationPlayer"), "animation_finished")
	previous.queue_free()
	$CanvasLayer/Left.set_disabled(false)
	$CanvasLayer/Right.set_disabled(false)

func save_current_scenario():
	save_screen_data()
	var savedFile
	if singleton.isWeb != null:
		savedFile = singleton.load_file_as_JSON("user://saved_scenarios.json")
	else:
		savedFile = singleton.load_file_as_JSON("res://saved_scenarios.json")
	if savedFile["Saves"] == null:
		savedFile["Saves"] = {}
	if scenarioDict["EditorDetails"].has("StoryData"):
		scenarioDict["EditorDetails"]["StoryData"] = node_data_to_JSON(scenarioDict["EditorDetails"]["StoryData"])
	savedFile["Saves"][currentScenario] = scenarioDict
	if singleton.isWeb != null:
		singleton.send_save_file(savedFile)
	var savejson = File.new()
	if singleton.isWeb != null:
		savejson.open("user://saved_scenarios.json", File.WRITE)
	else:
		savejson.open("res://saved_scenarios.json", File.WRITE)
	savejson.store_line(to_json(savedFile))
	savejson.close()

func node_data_to_JSON(data):
	var jsonNodeData = str2var(var2str(data))
	for story in jsonNodeData:
		for node in jsonNodeData[story]:
			if node != "Start":
				if typeof(jsonNodeData[story][node]["position"]) == TYPE_VECTOR2:
					jsonNodeData[story][node]["position"] = [jsonNodeData[story][node]["position"].x, jsonNodeData[story][node]["position"].y]
			for connection in jsonNodeData[story][node]["connections"]:
				for i in range(0, jsonNodeData[story][node]["connections"][connection].size()):
					if typeof(jsonNodeData[story][node]["connections"][connection][i]) == TYPE_VECTOR2:
						jsonNodeData[story][node]["connections"][connection][i] = [jsonNodeData[story][node]["connections"][connection][i].x, jsonNodeData[story][node]["connections"][connection][i].y]
	return jsonNodeData

#func load_scenario(scenarioName):
#	currentScenario = scenarioName
func send_scenario_to_db(name):
#	scenarioDict.erase("EditorDetails")
	scenarioDict["id"] = singleton.currentPlayer + "-" + name
	scenarioDict["isPublished"] = false
	scenarioDict["username"] = singleton.currentPlayer
	scenarioDict["rating"] = null
	
	var json = to_json(scenarioDict)
#	json = json.replace("'","")
#	json = json.replace("\\n","")
	var code="""
		var xmlHttp = new XMLHttpRequest();
		xmlHttp.open("PUT", "https://pixeldr.azurewebsites.net/gameapis/cosmosdbapi/new-scenario/""" + singleton.currentPlayer + """", true);
		xmlHttp.setRequestHeader("Content-Type", "application/json");
		xmlHttp.send(`%s`);
		xmlHttp.response;""" % (json)
	print(code)
	var response = JavaScript.eval(code)
	print(response)
	delete_from_save()

func delete_from_save():
	#Delete file:
	var savedScenarios = {}
	if singleton.isWeb != null:
		savedScenarios = singleton.load_file_as_JSON("user://saved_scenarios.json")
	else:
		savedScenarios = singleton.load_file_as_JSON("res://saved_scenarios.json")
	
	savedScenarios["Saves"].erase(currentScenario)
	singleton.send_save_file(savedScenarios)
	
	#Add locally:
	var savejson = File.new()
	if singleton.isWeb != null:
		savejson.open("user://saved_scenarios.json", File.WRITE)
	else:
		savejson.open("res://saved_scenarios.json", File.WRITE)
	savejson.store_line(to_json(savedScenarios))
	savejson.close()
	
	
