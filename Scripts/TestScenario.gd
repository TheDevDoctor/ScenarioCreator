extends Container

onready var viewport = $ScenarioDetails/ViewportContainer/Viewport
var history = false
var examinations = false
var use_item = false
var complete = true
var testing = false


func _ready():
	set_process_unhandled_key_input(true)
	check_completion()
	
	$ScenarioDetails/NinePatchRect/Buttons/Test.connect("pressed", self, "test_pressed")
	$ScenarioDetails/NinePatchRect/Buttons/Send.connect("pressed", self, "send_pressed")
	$ScenarioDetails/EndTest.connect("pressed", self, "end_test_pressed")
	
	$SendScenarioPanel/Buttons/Send.connect("pressed", self, "send_scenario")
	$SendScenarioPanel/Buttons/Cancel.connect("pressed", self, "cancel_pressed")
	
	if complete:
		complete_scenario_true()


func _input(event):
	if testing:
		if event is InputEventMouse:
			var ev = event
			ev.position -= Vector2(150, 108)
			viewport.input(ev)
			event.position += Vector2(150, 108)
		else:
			viewport.input(event)

func _unhandled_key_input(event):
	if testing:
		viewport.get_node("World/playerNode/Player")._unhandled_key_input(event)
		if history:
			viewport.get_node("World/GUI/pixelBotBox")._unhandled_key_input(event)
		if examinations:
			viewport.get_node("World/GUI/Examinations/Patch9Frame")._unhandled_key_input(event)
		if use_item:
			viewport.get_node("World/GUI/UseItem")._unhandled_key_input(event)

func check_completion():
	var scenario = $"../..".scenarioDict
	if scenario.has("PatientDetails") == false:
		complete = false
	if scenario.has("Vitals") == false:
		complete = false
	if scenario.has("ScenarioDetails") == false:
		complete = false
	if scenario["Answers"].has("Prescriptions") == false:
		complete = false
	if scenario["Answers"].has("Contact") == false:
		complete = false
	if scenario["Answers"].has("Procedures") == false:
		complete = false
	if scenario.has("History") == false:
		complete = false
	if scenario.has("Examinations") == false:
		complete = false
	if scenario.has("Investigations") == false:
		complete = false
	if scenario.has("Explanation") == false:
		complete = false
	if scenario.has("Story") == false:
		complete = false
	else:
		if scenario["Story"].has("Before Ix") == false:
			complete = false
		if scenario["Story"].has("Repeated Text") == false:
			complete = false
		if scenario["Story"].has("After Ix") == false:
			complete = false

func complete_scenario_true():
	$ScenarioDetails/NinePatchRect/Buttons.show()
	$ScenarioDetails/NinePatchRect/Congrats.show()
	
	$ScenarioDetails/NinePatchRect/TextureRect.hide()
	$ScenarioDetails/NinePatchRect/NotDone.hide()


func test_pressed():
	testing = true
	$ScenarioDetails/ViewportContainer.show()
	$ScenarioDetails/EndTest.show()

func end_test_pressed():
	$ScenarioDetails/ViewportContainer.hide()
	$ScenarioDetails/EndTest.hide()

func send_pressed():
	$Cover.show()
	$SendScenarioPanel.show()


func send_scenario():
	var name = $SendScenarioPanel/Name.get_text()
	if name.length() == 0:
		return
	$"/root/MainFrame".send_scenario_to_db(name)

	$Cover.hide()
	$SendScenarioPanel.hide()
	$"/root/MainFrame".exit_to_load_screen()


func cancel_pressed():
	$Cover.hide()
	$SendScenarioPanel.hide()