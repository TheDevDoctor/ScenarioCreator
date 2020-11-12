extends Node2D

var storyDict = {}
var patientDetailsDict = {}
var investigationDict = {}
var examinationDetailsDict = {}
var prescriptionDict = {}
var explanation
var characters = ["Player", "Patient"]

var bConnectionInt = 0



var activeInputs = []
var activeOutputs = []
var dNum = 0
var qNum = 0
var canResize = false
var currentSubscreen = null
var currentStory = "Before Ix"
var stories = ["Before Ix", "Repeated Text", "After Ix"]

var left = false
var right = false
var up = false
var down = false
const scrollSpeed = 1000

var pressed = false
var mouse_enter = false
var mouse_enter_InOut = false
var mouse_exit_InOut = false
var object_dragged = false
var background_dragged = false
var canMakeConnection = false
var canDrawLine = false
var drawing = false
var mousePressed = false
var overCover = false 
var direction_hovered = false
var canMoveCamera = false
var pos
var panelPos
var currentPanel
var camera
var oldPos
var cameraPos
var buttons = []

var startingNode
var endNode
var currentOutput
var sideScreen

var posFrom = Vector2(0,0)
var posTo = Vector2(0,0)

func _ready():
	if $"/root/MainFrame".currentScreen == 1:
		currentStory = "Before Ix"
	elif $"/root/MainFrame".currentScreen == 4:
		currentStory = "Repeated Text"
	elif $"/root/MainFrame".currentScreen == 6:
		currentStory = "After Ix"

#	$Control.set_name(currentStory)
	camera = get_node("Camera2D")

	var left = get_node("GUI/TextureFrame/Left")
	left.connect("pressed", self, "change_story_screen", [left])
	var right = get_node("GUI/TextureFrame/Right")
	right.connect("pressed", self, "change_story_screen", [right])
	for button in $GUI/TextureRect.get_children():
		button.connect("mouse_entered", self, "direction_hovered", [button])
		button.connect("mouse_exited", self, "direction_exited", [button])
	
#	$GUI/NinePatchRect/Buttons1/exit.connect("pressed", self, "close_dialogue_editor")
	
	$GUI/NinePatchRect/Buttons1/addDialogue.connect("pressed", self, "button_pressed", [$GUI/NinePatchRect/Buttons1/addDialogue])
	$GUI/NinePatchRect/Buttons1/addBranching.connect("pressed", self, "button_pressed", [$GUI/NinePatchRect/Buttons1/addBranching])
	$GUI/NinePatchRect2/HBoxContainer/ZoomIn.connect("pressed", self, "button_pressed", [$GUI/NinePatchRect2/HBoxContainer/ZoomIn])
	$GUI/NinePatchRect2/HBoxContainer/ZoomOut.connect("pressed", self, "button_pressed", [$GUI/NinePatchRect2/HBoxContainer/ZoomOut])
	

	var startArea2D = get_node("Control/Start/Output/Area2D")
	startArea2D.connect("mouse_entered", self, "_on_mouse_enter_area2D", [startArea2D])
	if storyDict.has("Start") == false:
		storyDict["Start"] = {"connections": {}}
	
	
	var data = get_node("../..").scenarioDict

	if data.has("Story"):
		if data["Story"].has(currentStory):
			storyDict = data["EditorDetails"]["StoryData"][currentStory] 
			storyJSON = data["Story"][currentStory]
			print_loaded_data()

#	currentStory = 0
	set_process(true)
	set_process_input(true)
	set_process_unhandled_key_input(true)
	


func _input(event):
	if event is InputEventMouseButton:
		if  (event.button_index == BUTTON_LEFT and event.pressed):  
			mousePressed = true
		elif (event.button_index == BUTTON_LEFT and !event.pressed):
			mousePressed = false
			if drawing == true:  
				if canMakeConnection == false:
					line_failed()
				elif canMakeConnection == true:
					line_success() 

func _unhandled_key_input(event):
	if event.is_action_pressed("add_dialogue"):
		add_dialogue("Dialogue")
	elif event.is_action_pressed("add_question"):
		add_dialogue("Question")
	elif event.is_action_pressed("ui_left"):
		canMoveCamera = true
		left = true
	elif event.is_action_released("ui_left"):
		canMoveCamera = false
		left = false
	elif event.is_action_pressed("ui_right"):
		canMoveCamera = true
		right = true
	elif event.is_action_released("ui_right"):
		canMoveCamera = false
		right = false
	elif event.is_action_pressed("ui_up"):
		canMoveCamera = true
		up = true
	elif event.is_action_released("ui_up"):
		canMoveCamera = false
		up = false
	elif event.is_action_pressed("ui_down"):
		canMoveCamera = true
		down = true
	elif event.is_action_released("ui_down"):
		canMoveCamera = false
		down = false
	elif event.is_action_pressed("zoom_in"):
		change_zoom("ZoomIn")
	elif event.is_action_pressed("zoom_out"):
		change_zoom("ZoomOut")


func _process(delta):
	pos = get_global_mouse_position()
	if mouse_enter == true:
		if mousePressed == true:
			currentPanel.set_global_position(Vector2(pos.x - 10, pos.y))# - (currentPanel.get_size().y/2)))
			object_dragged = true
			update_lines(currentPanel)
			update_position(currentPanel)
		else:
			object_dragged = false

	elif canDrawLine == true:
		if mousePressed == true and canMakeConnection == false:
			drawing = true
			posTo = pos
			update()
	elif canResize == true:
		if mousePressed == true:
			resize_panel(pos, oldPos)
	elif overCover == true:
		if mousePressed == true:
			closeSubScreen()
			mousePressed = false
	
	elif direction_hovered:
		if mousePressed:
			canMoveCamera = true
		else:
			canMoveCamera = false
#	else: 
#		cameraPos = camera.get_global_position()
#		if Input.is_mouse_button_pressed(BUTTON_LEFT):
#			var posDiff = pos - oldPos
#			camera.set_global_position(cameraPos - (posDiff * 2))
#			background_dragged = true
#		else:
#			background_dragged = false
	oldPos = pos
	if canMoveCamera:
		if left == true:
			cameraPos = camera.get_global_position()
			camera.set_global_position(Vector2(cameraPos.x - (scrollSpeed * delta), cameraPos.y))
		elif right == true:
			cameraPos = camera.get_global_position()
			camera.set_global_position(Vector2(cameraPos.x + (scrollSpeed * delta), cameraPos.y))
		elif up == true:
			cameraPos = camera.get_global_position()
			camera.set_global_position(Vector2(cameraPos.x, cameraPos.y - (scrollSpeed * delta)))
		elif down == true:
			cameraPos = camera.get_global_position()
			camera.set_global_position(Vector2(cameraPos.x, cameraPos.y + (scrollSpeed * delta)))


func resize_panel(pos, oldPos):
	var sizeIncrease = pos - oldPos
	currentPanel.set_size(currentPanel.get_size() + sizeIncrease)

func direction_hovered(button):
	direction_hovered = true
	if button.get_name() == "Up":
		up = true
	elif button.get_name() == "Right":
		right = true
	elif button.get_name() == "Down":
		down = true
	elif button.get_name() == "Left":
		left = true

func direction_exited(button):
	canMoveCamera = false
	direction_hovered = false
	if button.get_name() == "Up":
		up = false
	elif button.get_name() == "Right":
		right = false
	elif button.get_name() == "Down":
		down = false
	elif button.get_name() == "Left":
		left = false

func update_lines(panel):
	if activeOutputs.has(panel.get_name()):
		for connection in storyDict[panel.get_name()]["connections"]:
			if "question" in panel.get_name():
				storyDict[panel.get_name()]["connections"][connection][0] = (panel.get_node("OutputContainer/" + storyDict[panel.get_name()]["connections"][connection][2]).get_global_position() + Vector2(8, 5))
			else:
				storyDict[panel.get_name()]["connections"][connection][0] = (panel.get_node("Output").get_global_position() + Vector2(8, 5))

	if activeInputs.has(panel.get_name()):
		for item in storyDict:
			if "question" in item:
				for connection in storyDict[item]["connections"]:
					if storyDict[item]["connections"][connection].has(panel.get_name()):
						storyDict[item]["connections"][connection][1] = (panel.get_node("Input").get_global_position() + Vector2(8, 5))
			else:
				if storyDict[item]["connections"].has(panel.get_name()):
					storyDict[item]["connections"][panel.get_name()][1] = (panel.get_node("Input").get_global_position() + Vector2(8, 5))
	update()

func update_position(panel):
	storyDict[panel.get_name()]["position"] = panel.get_position()

func button_pressed(button):
	if "Zoom" in button.get_name():
		change_zoom(button.get_name())
	else:
		if button.get_name() == "addDialogue":
			add_dialogue("Dialogue")
		elif button.get_name() == "addBranching":
			add_dialogue("Question")
#		print(storyDict)

func add_dialogue(choice):
	var node
	if choice == "Dialogue":
		node = preload("res://Scenes/textDialogueBox.tscn").instance()
		node.set_name("dialogue" + str(dNum))
		dNum += 1
	elif choice == "Question":
		node = preload("res://Scenes/textQuestionsBox.tscn").instance()
		node.set_name("question" + str(qNum))
		qNum += 1
	get_node("Control").add_child(node)
	node.set_position(camera.get_global_position())
	for btn in node.get_node("Speaking/NinePatchRect").get_children():
		btn.connect("pressed", self, "change_speaking", [btn])
#	node.get_node("Label/Speaking").add_separator()
#	for character in characters:
#		node.get_node("Label/Speaking").add_item(character)
	storyDict[node.get_name()] = {"connections": {}, "position": node.get_global_position()}
	connect_node_signals(node)


func _draw():
#	draw_line(posFrom, posTo, Color(255, 0, 0), 1)
	if drawing == true:
		draw_line(posFrom, posTo, Color8(32.68, 239.06, 113.3, 255/2), 4)
		draw_line(posFrom, posTo, Color8(32.68, 239.06, 113.3, 255/2), 3)

	for key in storyDict:
#		print(key)
		if storyDict[key]["connections"].size() > 0:
			for line in storyDict[key]["connections"]:
				var pos1 = storyDict[key]["connections"][line][0] 
				var pos2 = storyDict[key]["connections"][line][1]

				draw_line(pos1, pos2, Color8(32.68, 239.06, 113.3, 255/2), 4)
				draw_line(pos1, pos2, Color8(32.68, 239.06, 113.3, 255/2), 3)

func change_zoom(button):
	if button == "ZoomIn":
		camera.set_zoom(camera.get_zoom() - Vector2(0.5, 0.5))
	elif button == "ZoomOut":
		camera.set_zoom(camera.get_zoom() + Vector2(0.5, 0.5))

func connect_node_signals(node):
	var draggableArea = node.get_node("DragBar/Draggable")
	draggableArea.connect("mouse_entered", self, "_on_mouse_enter", [node])
	draggableArea.connect("mouse_exited", self, "_on_mouse_exit", [node])

	var inputArea = node.get_node("Input/Area2D")

	inputArea.connect("mouse_entered", self, "_on_mouse_enter_area2D", [inputArea])
	inputArea.connect("mouse_exited", self, "_on_mouse_exit_area2D", [inputArea])

	if "dialogue" in node.get_name(): 
		var outputArea = node.get_node("Output/Area2D")
		outputArea.connect("mouse_entered", self, "_on_mouse_enter_area2D", [outputArea])
		outputArea.connect("mouse_exited", self, "_on_mouse_exit_area2D", [outputArea])
	elif "question" in node.get_name():
		var outputAreas = node.get_node("OutputContainer").get_children()
		for area in outputAreas:
			area.get_node("Area2D").connect("mouse_entered", self, "_on_mouse_enter_area2D", [area.get_node("Area2D")])
			area.get_node("Area2D").connect("mouse_exited", self, "_on_mouse_exit_area2D", [area.get_node("Area2D")])

	var resizeArea = node.get_node("Resize/Area2D")
	resizeArea.connect("mouse_entered", self, "_on_mouse_enter_resizeArea2D", [resizeArea])
	resizeArea.connect("mouse_exited", self, "_on_mouse_exit_resizeArea2D", [resizeArea])

	var close = node.get_node("Close")
	close.connect("pressed", self, "remove_story_node", [node])

func remove_story_node(panel):
	panel.queue_free()
	storyDict.erase(panel.get_name())
	for node in storyDict:
		if storyDict[node]["connections"].has(panel.get_name()):
			storyDict[node]["connections"].erase(panel.get_name())
	update()


func _on_mouse_enter(panel):
	print("enter")
	if object_dragged == false:
		panel.get_node("DragBar").set_self_modulate(Color(0.91, 0.38, 1, 1))
		mouse_enter = true
		currentPanel = panel
		panelPos = currentPanel.get_global_position()

func _on_mouse_exit(panel):
	if object_dragged == false:
		panel.get_node("DragBar").set_self_modulate(Color(0.35, 0.78, 0.97, 1))
		mouse_enter = false

func _on_mouse_enter_area2D(area):
	print("entered")
	if "Output" in area.get_parent().get_name(): 
		canDrawLine = true 
		area.get_parent().set_self_modulate(Color(0.47, 0.93, 0.99, 1))
		posFrom = area.get_global_position()
		currentOutput = area.get_parent().get_name()

		if "orrect" in area.get_parent().get_name():
			startingNode = area.get_node("../../..")
		else:
			startingNode = area.get_node("../..")
	else:
		canMakeConnection = true
		endNode = area.get_node("../..")
		area.get_parent().set_self_modulate(Color(0.47, 0.93, 0.99, 1))
		posTo = area.get_global_position()
		update()

func _on_mouse_exit_area2D(area):
	if area.get_node("..").get_name() == "Input":
		if activeInputs.has(area.get_node("../..").get_name()):
			area.get_parent().set_self_modulate(Color(0.07, 0.94, 0.1, 1))
		else:
			area.get_parent().set_self_modulate(Color(1, 1, 1, 1))
	else:
		area.get_parent().set_self_modulate(Color(1, 1, 1, 1))


	canMakeConnection = false
#	mouse_exit_InOut = true

func line_failed():
	canDrawLine = false 
	drawing = false
	posTo = posFrom
	update()

func line_success():

	if ("dialogue" in startingNode.get_name()) and storyDict[startingNode.get_name()]["connections"].size() > 0:
		storyDict[startingNode.get_name()]["connections"].clear()
		storyDict[startingNode.get_name()]["connections"][endNode.get_name()] = [posFrom, posTo, currentOutput]
	elif "question" in startingNode.get_name():
		for connection in storyDict[startingNode.get_name()]["connections"]:
			if storyDict[startingNode.get_name()]["connections"][connection].has(currentOutput):
				storyDict[startingNode.get_name()]["connections"].erase(connection)
		storyDict[startingNode.get_name()]["connections"][str(bConnectionInt)] = [posFrom, posTo, currentOutput, endNode.get_name()]
		bConnectionInt += 1
	else:
		storyDict[startingNode.get_name()]["connections"][endNode.get_name()] = [posFrom, posTo, currentOutput]

	activeOutputs.append(startingNode.get_name())
	activeInputs.append(endNode.get_name())
	if "question" in startingNode.get_name():
		startingNode.get_node("OutputContainer/" + currentOutput).set_self_modulate(Color(0.07, 0.94, 0.1, 1))
	else:
		startingNode.get_node("Output").set_self_modulate(Color(0.07, 0.94, 0.1, 1))
	endNode.get_node("Input").set_self_modulate(Color(0.07, 0.94, 0.1, 1))
	drawing = false
	canDrawLine = false 
	canMakeConnection = false
	update()



func _on_mouse_enter_resizeArea2D(area):
	area.get_parent().set_self_modulate(Color(0.07, 0.94, 0.1, 1))
	currentPanel = area.get_node("../..")
	canResize = true


func _on_mouse_exit_resizeArea2D(area):
	area.get_parent().set_self_modulate(Color(1, 1, 1, 1))
	canResize = false

onready var animPlayer = get_node("AnimationPlayer")


var screenOpen = false
var canCloseScreen = true

func side_screen_open():
	if screenOpen == false: 
		animPlayer.play("sideScreenMove")
		screenOpen = true
	else:
		animPlayer.play_backwards("sideScreenMove")
		screenOpen = false



func _on_Cover_mouse_enter():
	overCover = true

func _on_Cover_mouse_exit():
	overCover = false

func closeSubScreen():
	get_node(currentSubscreen).return_data()
	get_node(currentSubscreen).queue_free()

	get_node("GUI/Cover").show()
	overCover = false
	animPlayer.play_backwards("sideScreenMove")
	screenOpen = false

func change_story_screen(btn):
	if btn.get_name() == "Right":
		if currentStory < 2:
			currentStory += 1
	else:
		if currentStory > 0:
			currentStory -= 1
	get_node("GUI/TextureFrame/StoryLabel").set_text(currentStory)
	var sceneChildren = get_node("Stories").get_children()
	for child in sceneChildren:
		if child.get_name() == currentStory:
			child.show()
		else:
			child.hide()
	update()

func make_json(finalDict):
	var json = File.new()
	json.open("res://test3", File.WRITE)
	json.store_line(to_json(finalDict))
	json.close()

var storyJSON = {}
func _on_makeJSON_pressed():
	var finalDict = {}
	make_story_json()
	finalDict["Story"] = storyJSON
#	finalDict["PatientDetails"] = patientDetailsDict
#	finalDict["ExaminationFindings"] = examinationDetailsDict
#	finalDict["Investigations"] = investigationDict
#	finalDict["Prescriptions"] = prescriptionDict
#	finalDict["Explanation"] = explanation
	
	make_json(finalDict)

func make_story_json():
	storyJSON = {}
#	for story in storyDict:
	for node in storyDict:
		if node == "Start":
			var startingNodes = storyDict[node]["connections"].keys()
			if startingNodes.size() > 0:
				storyJSON[node] = startingNodes[0]

		else:
			storyJSON[node] = {"content": []}
			var text = get_node("Control/" + node + "/Text").get_text()
			var speakingNode = get_node("Control/" + node + "/Speaking")
			var speaking = speakingNode.get_text()
			storyJSON[node]["content"].append(text)
			if storyDict[node]["connections"].size() > 0:
				storyJSON[node]["content"].append({"speaking": speaking})
				for connection in storyDict[node]["connections"]:
					if "dialogue" in node:
						storyJSON[node]["content"][1]["divert"] = connection
					else:
						var output = storyDict[node]["connections"][connection][2]
						var optionText = get_node("Control/" + node + "/HBoxContainer/LineEditContainer/" + output).get_text()
						var linkPath = storyDict[node]["connections"][connection][3]
						if "OutputIncorrect" in output: 
							storyJSON[node]["content"].append({"linkPath": linkPath, "option": optionText, "Answer": false})
						else:
							storyJSON[node]["content"].append({"linkPath": linkPath, "option": optionText, "Answer": true})
			else:
				storyJSON[node]["content"].append({"isEnd": true, "speaking": speaking})

func close_dialogue_editor():
	make_story_json()
	var data = {"Dialogue": {"StoryDict": storyJSON, "NodeDict": storyDict}}
#	get_node("/root/singleton").goto_scene("res://MainScreen.tscn", data)

#func load_data(data):
#	if data.has("Dialogue"):
#		storyJSON = data["Dialogue"]["StoryDict"]
#		storyDict = data["Dialogue"]["NodeDict"]
#		print_loaded_data()
#	else:
#		print("The data is of the incorrect type")

func change_speaking(btn):
	var currentInt = characters.find(btn.get_node("../..").get_text())
	var nextInt
	if "Next" in btn.get_name():
		if currentInt == (characters.size() - 1):
			btn.get_node("../..").set_text(characters[0])
		else:
			btn.get_node("../..").set_text(characters[currentInt + 1])
	elif "Prev" in btn.get_name():
		if currentInt == 0:
			btn.get_node("../..").set_text(characters[characters.size()-1])
		else:
			btn.get_node("../..").set_text(characters[currentInt - 1])


func print_loaded_data():
	for node in storyDict:
		if node != "Start":
			var scene
			if "dialogue" in node:
				scene = preload("res://Scenes/textDialogueBox.tscn").instance()
				dNum += 1
				scene.get_node("Text").set_text(storyJSON[node]["content"][0])
				scene.get_node("Speaking").set_text(storyJSON[node]["content"][1]["speaking"])
				get_node("Control").add_child(scene)
			elif "question" in node:
				scene = preload("res://Scenes/textQuestionsBox.tscn").instance()
				qNum += 1
				scene.get_node("Text").set_text(storyJSON[node]["content"][0])
				scene.get_node("Speaking").set_text(storyJSON[node]["content"][1]["speaking"])
				get_node("Control").add_child(scene)
				var NoOfQs = storyJSON[node]["content"].size() - 2
				if NoOfQs > 0:
					var diff = NoOfQs - 4
					scene.load_q_number(diff)
				for i in range(2, storyJSON[node]["content"].size()):
					scene.get_node("HBoxContainer/LineEditContainer/").get_child(i - 2).set_text(storyJSON[node]["content"][i]["option"])
			

			scene.set_name(node)
			for btn in scene.get_node("Speaking/NinePatchRect").get_children():
				btn.connect("pressed", self, "change_speaking", [btn])
			scene.set_position(storyDict[node]["position"])

			connect_node_signals(scene)
		if storyDict[node]["connections"].size() > 0:
			activeOutputs.append(node)
			for nd in storyDict[node]["connections"]:
				if "question" in node:
					activeInputs.append(storyDict[node]["connections"][nd][3])
				else:
					activeInputs.append(nd)
	update()
