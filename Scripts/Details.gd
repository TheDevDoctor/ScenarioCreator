extends Container

# class member variables go here, for example:
# var a = 2
var data 

func _ready():
	$PatientDetails/Change.connect("pressed", self, "change_sprite_pressed")
	set_base_data()
	data = get_node("../..").scenarioDict
	if data.has("ScenarioDetails"):
		load_data()
	
	connect_optionButton_function()

func set_base_data():
	var difficulties = ["Junior", "Registrar", "Consultant", "House"] 
	$ScenarioDetails/VBoxContainer/Difficulty.add_separator()
	for difficulty in difficulties:
		$ScenarioDetails/VBoxContainer/Difficulty.add_item(difficulty)
	var specialties = ["Oncology", "Paediatrics", "Cardiology", "Respiration", "Endocrinology", "Ear, Nose and Throat", "Gastroenterology", "Geriatrics", "Haematology", "Infectious Diseases", "Nephrology", "Urology", "Orthopaedics", "Psychiatry", "Neurology", "Opthalmology", "Plastic surgery", "Dermatology", "Obstetrics", "Gynaecology", "Rheumatology", "Surgery", "Sexual Health"]
	$ScenarioDetails/VBoxContainer/Specialty.add_separator()
	for spec in specialties:
		$ScenarioDetails/VBoxContainer/Specialty.add_item(spec)
	var priority = ["1: Urgent", "2: Serious", "3: Non-urgent"]
	$ScenarioDetails/VBoxContainer/Priority.add_separator()
	for prior in priority:
		$ScenarioDetails/VBoxContainer/Priority.add_item(prior)
	var wards = ["Emergency Department"]
	$PatientDetails/VBoxContainer/Ward.add_separator()
	for ward in wards:
		$PatientDetails/VBoxContainer/Ward.add_item(ward)

func change_sprite_pressed():
	if $PatientDetails/Change.get_text() == "Change":
		$HelpNodes.hide()
		$PatientDetails/SpriteGrid.show()
		for i in range(0, 6):
			var button = load("res://Scenes/bedSpriteButton.tscn").instance()
			button.get_node("Sprite").set_frame(i)
			button.set_name(str(i))
			button.connect("pressed", self, "bed_selected", [button])
			$PatientDetails/SpriteGrid/ScrollContainer/GridContainer.add_child(button)
		$PatientDetails/VBoxContainer.hide()
		$PatientDetails/Change.text = "Accept"
	else:
		$HelpNodes.show()
		$PatientDetails/SpriteGrid.hide()
		$PatientDetails/VBoxContainer.show()
		$PatientDetails/Change.text = "Change"

func bed_selected(button):
	var sprite = int(button.get_name())
	$PatientDetails/Sprite.set_frame(sprite)

func connect_optionButton_function():
	for node in $ScenarioDetails/VBoxContainer.get_children():
		node.connect("item_selected", singleton, "hide_label", [node])
	

	$PatientDetails/VBoxContainer/Ward.connect("item_selected", singleton, "hide_label", [$PatientDetails/VBoxContainer/Ward])

func load_data():
	$PatientDetails/Sprite.set_frame(data["ScenarioDetails"]["Sprite"])
	
#	$WebsiteInfo/TextEdit.set_text(data["description"])
	
	if data["ScenarioDetails"]["Difficulty"].length() > 0:
		var difficulties = ["Junior", "Registrar", "Consultant", "House"] 
		$ScenarioDetails/VBoxContainer/Difficulty.select(difficulties.find(data["ScenarioDetails"]["Difficulty"]) + 1)
		$ScenarioDetails/VBoxContainer/Difficulty/Label.hide()
	
	if data["ScenarioDetails"]["Specialty"].length() > 0:
		var specialties = ["Oncology", "Paediatrics", "Cardiology", "Respiration", "Endocrinology", "Ear, Nose and Throat", "Gastroenterology", "Geriatrics", "Haematology", "Infectious Diseases", "Nephrology", "Urology", "Orthopaedics", "Psychiatry", "Neurology", "Opthalmology", "Plastic surgery", "Dermatology", "Obstetrics", "Gynaecology", "Rheumatology", "Surgery", "Sexual Health"]
		$ScenarioDetails/VBoxContainer/Specialty.select(specialties.find(data["ScenarioDetails"]["Specialty"]) + 1)
		$ScenarioDetails/VBoxContainer/Specialty/Label.hide()
	
	if data["ScenarioDetails"]["Priority"].length() > 0:
		var priority = ["1: Urgent", "2: Serious", "3: Non-urgent"]
		$ScenarioDetails/VBoxContainer/Priority.select(priority.find(data["ScenarioDetails"]["Priority"]) + 1)
		$ScenarioDetails/VBoxContainer/Priority/Label.hide()
		
	if data["PatientDetails"]["Ward"].length() > 0:
		var wards = ["Emergency Department"]
		$PatientDetails/VBoxContainer/Ward.select(wards.find(data["PatientDetails"]["Ward"]) + 1)
		$PatientDetails/VBoxContainer/Ward/Label.hide()
	
	for detail in data["PatientDetails"]:
		if detail != "Ward" and $PatientDetails/VBoxContainer.has_node(detail):
			$PatientDetails/VBoxContainer.get_node(detail).set_text(data["PatientDetails"][detail])
	
	for detail in data["Vitals"]:
		if detail == "BP":
			$Vitals/VBoxContainer/BP/Systolic.set_text(data["Vitals"]["BP"]["Systolic"])
			$Vitals/VBoxContainer/BP/Diastolic.set_text(data["Vitals"]["BP"]["Diastolic"])
		else:
			$Vitals/VBoxContainer.get_node(detail).set_text(data["Vitals"][detail])
