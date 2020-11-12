extends Container

var medicines = {}
var procedures = {}
var medSearchArray = []
var callsSearchArray = []
var proceduresSearchArray = []
var currentType = "Medications"
var chosenMed
var prescriptionDict = {"OnceOnly": [], "Regular": [], "AsRequired": [], "Infusion": [], "Oxygen": []}
var proceduresChange = null
var calls = null
var infusionDrugsAdded = []
var altPres = false
var presType


func _ready():
	$Container/Panel/NinePatchRect/Types.connect("item_selected", self, "type_selected")
	var types = ["Medications", "Infusions", "Oxygen"]
	for type in types:
		$Container/Panel/NinePatchRect/Types.add_item(type)
	
	medicines = singleton.load_file_as_JSON("res://JSON_files/prescribing.json")
	for med in medicines[currentType]:
		medSearchArray.append(med)
	medSearchArray.sort()
	update_search_list(medSearchArray)
	
	procedures = singleton.load_file_as_JSON("res://JSON_files/collectables.json")
	for pro in procedures:
		proceduresSearchArray.append(pro)
	proceduresSearchArray.sort()
	
	var callDict = singleton.load_file_as_JSON("res://JSON_files/bleepInteractions.json")
	for call in callDict:
		callsSearchArray.append(call)
	callsSearchArray.sort()
	
	for button in $Container/Panel/Editor/CheckButtons.get_children():
		button.connect("pressed", self, "check_button_pressed", [button])
	$Container/Panel/Editor/HBoxContainer/Add.connect("pressed", self, "add_prescription_pressed")
	$Container/Panel/Editor/HBoxContainer/Cancel.connect("pressed", self, "cancel_prescription_pressed")
	$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid/AddDrug.connect("pressed", self, "add_infusion_drug_pressed")
	$Container/Panel/NinePatchRect/InfDone.connect("pressed", self, "close_infusion_list")
	$Container/Panel/NinePatchRect/Search.connect("text_changed", self, "search_text_changed")
	$ScenarioDetails/Add.connect("pressed", self, "add_procedure_pressed")
	$Contacts/Add.connect("pressed", self, "add_contacts_pressed")
	
	var data = get_node("../..").scenarioDict
	if data["Answers"].has("Procedures"):
		proceduresChange = data["Answers"]["Procedures"]
		calls = data["Answers"]["Contact"]
		prescriptionDict = data["Answers"]["Prescriptions"]
		load_management_data()


func update_search_list(array, infusion = false):
	var container = get_node("Container/Panel/NinePatchRect/ScrollContainer/VBoxContainer")
	singleton.clear_container(container)
	for med in array:
		var button = ix_button_return(med)
		if infusion:
			button.connect("pressed", self, "infusion_chosen", [button])
		else:
			button.connect("pressed", self, "prescription_chosen", [button])
		if med == chosenMed:
			button.set_pressed(true)
		container.add_child(button)
	container.get_node("..").set_v_scroll(0)

func search_text_changed(text):
	var array = []
	if text.length() > 0:
		for med in medSearchArray:
			if text.to_lower() in med.to_lower():
				array.append(med)
		update_search_list(array)
	else:
		update_search_list(medSearchArray)

func ix_button_return(med):
	var button = TextureButton.new()
	button.texture_normal = load("res://Graphics/IxButton.png")
	button.texture_hover = load("res://Graphics/IxButtonHover.png")
	button.texture_pressed = load("res://Graphics/IxButtonPressed.png")
	button.toggle_mode = true
	button.set_name(med)
	
	var label = Label.new()
	label.anchor_right = 1
	label.anchor_bottom = 1
	label.clip_text = true
	label.autowrap = true
	label.margin_right = -18
	label.margin_top = 5
	label.margin_left = 12
	label.margin_bottom = -5
	label.valign = VALIGN_CENTER
	label.set_text(med)
	button.add_child(label)
	
	return button

func form_search_array(variable, infusion = false):
	medSearchArray.clear()
	if infusion == false:
		for item in variable:
			medSearchArray.append(item)
		medSearchArray.sort()
		update_search_list(medSearchArray)
	else:
		for item in variable:
			if variable[item]["AsInfusion"] == true:
				medSearchArray.append(item)
		medSearchArray.sort()
		update_search_list(medSearchArray, true)
	
	

func type_selected(INT):
	currentType = $Container/Panel/NinePatchRect/Types.get_item_text(INT)
	form_search_array(medicines[currentType])

func prescription_chosen(button):
	if chosenMed != null:
		if $Container/Panel/NinePatchRect/ScrollContainer/VBoxContainer.has_node(chosenMed):
			$Container/Panel/NinePatchRect/ScrollContainer/VBoxContainer.get_node(chosenMed).set_pressed(false)
	chosenMed = button.get_name()
	open_editor()
	

func open_editor():
	if currentType == "Medications":
		open_medication_editor()
	elif currentType == "Infusions":
		open_infusions_editor()
	elif currentType == "Oxygen":
		open_oxygen_editor()

func open_medication_editor():
	$Container/Panel/PrescribedContainer.hide()
	$Container/Panel/Editor.show()
	$Container/Panel/Editor/CheckButtons.show()
	set_option_button_data($Container/Panel/Editor/ScrollContainer/MedicinesDetails/OnceOnly, chosenMed)
	set_option_button_data($Container/Panel/Editor/ScrollContainer/MedicinesDetails/Regular, chosenMed)
	set_option_button_data($Container/Panel/Editor/ScrollContainer/MedicinesDetails/AsRequired, chosenMed)

func open_infusions_editor():
	$Container/Panel/PrescribedContainer.hide()
	$Container/Panel/Editor.show()
	$Container/Panel/Editor/CheckButtons.hide()
	set_option_button_data($Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid, chosenMed)
	$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid.show()

func open_oxygen_editor():
	$Container/Panel/PrescribedContainer.hide()
	$Container/Panel/Editor.show()
	$Container/Panel/Editor/CheckButtons.hide()
	set_option_button_data($Container/Panel/Editor/ScrollContainer/MedicinesDetails/Oxygen, chosenMed)
	$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Oxygen/Label.set_text(chosenMed)
	$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Oxygen.show()
	

var activeTypes = []
func check_button_pressed(button):
	if button.is_pressed():
		activeTypes.append(button.get_name())
		get_node("Container/Panel/Editor/ScrollContainer/MedicinesDetails/" + button.get_name()).show()
	else:
		activeTypes.erase(button.get_name())
		get_node("Container/Panel/Editor/ScrollContainer/MedicinesDetails/" + button.get_name()).hide()

func set_option_button_data(TypeHBox, med):
	var children = TypeHBox.get_children()
	for child in children:
		if child.get_class() == "OptionButton":
			child.connect("item_selected", singleton, "hide_label", [child])
			child.connect("item_selected", self, "check_if_other", [child])
			child.get_node("Label").show()
			child.clear()
			child.add_separator()
			if medicines[currentType][med].has(child.get_name()):
				for item in medicines[currentType][med][child.get_name()]:
					child.add_item(item)
				child.add_item("Other")
			else:
				var array = []
				if child.get_name() == "Routes":
					array = ["PO", "IV", "SC", "IM"]
				elif child.get_name() == "Frequency":
					array = ["OD", "BD", "TDS", "QDS", "ON"]
				elif child.get_name() == "Duration":
					array = range(21)
				elif child.get_name() == "DurUnits":
					array = ["Hours", "Days", "Weeks", "Months"]
				elif child.get_name() == "Volume":
					array = ["1", "2", "3", "4", "5", "50", "100", "150", "200", "250", "500", "1000"]
				elif child.get_name() == "VolUnits":
					array = ["ml", "L"]
				elif child.get_name() == "RunTime":
					array = ["1", "2", "4", "5", "10", "15", "20", "24", "60"]
				elif child.get_name() == "RunTimeUnits":
					array = ["Seconds", "Minutes", "Hours"]
				elif child.get_name() == "Given":
					array = ["Continuous", "If below target"]
				elif child.get_name() == "Target Sats":
					array = ["88 - 92%", "94 - 98%"]
				elif child.get_name() == "Flow Rate":
					array = []
					for i in range(1, 16):
						array.append(str(i) + "L")
				for item in array:
					if str(item) != str(0):
						child.add_item(str(item))
				child.add_item("Other")
		elif child.get_class() == "HBoxContainer":
			child.get_node("Min").connect("item_selected", self, "check_if_other", [child.get_node("Min")])
			child.get_node("Max").connect("item_selected", self, "check_if_other", [child.get_node("Max")])
			child.get_node("Min").clear()
			child.get_node("Max").clear()
			child.get_node("Min").add_separator()
			child.get_node("Max").add_separator()
			child.get_node("Max").connect("item_selected", singleton, "hide_label", [child.get_node("Max")])
			child.get_node("Min").connect("item_selected", singleton, "hide_label", [child.get_node("Min")])
			var array = []
			if child.get_name() == "Doses":
				if medicines["Medications"][med]["Doses"] != null:
					array = medicines["Medications"][med]["Doses"]
			elif child.get_name() == "Volume":
				array = ["1", "2", "3", "4", "5", "50", "100", "150", "200", "250", "500", "1000"]
			elif child.get_name() == "RunTime":
				array = ["1", "2", "4", "5", "10", "15", "20", "24", "60"]
			for item in array:
				child.get_node("Min").add_item(item)
				child.get_node("Max").add_item(item)
			child.get_node("Min").add_item("Other")
			child.get_node("Max").add_item("Other")
			
func add_prescription_pressed():
	$Container/Panel/Editor.hide()
	$Container/Panel/PrescribedContainer.show()
	if altPres:
		add_to_alternatives()
		altPres = false
	else:
		add_to_prescribed()
	activeTypes.clear()
	$Container/Panel/NinePatchRect/ScrollContainer/VBoxContainer.get_node(chosenMed).set_pressed(false)
	chosenMed = null

func cancel_prescription_pressed():
	$Container/Panel/Editor.hide()
	$Container/Panel/PrescribedContainer.show()
	$Container/Panel/NinePatchRect/ScrollContainer/VBoxContainer.get_node(chosenMed).set_pressed(false)
	activeTypes.clear()
	chosenMed = null
	if altPres:
		altPres = false

func add_to_prescribed():
	if currentType == "Medications":
		for type in activeTypes:
			var child = get_node("Container/Panel/Editor/ScrollContainer/MedicinesDetails/" + type)
			$Container/Panel/Editor/CheckButtons.get_node(type).set_pressed(false)
			child.hide()
			prescriptionDict[child.get_name()].append({chosenMed : {}})
			for node in child.get_children():
				if node.get_class() == "OptionButton":
					if node.is_visible():
						prescriptionDict[child.get_name()][prescriptionDict[child.get_name()].size() - 1][chosenMed][node.get_name()] = node.get_item_text(node.get_selected())
						prescriptionDict[child.get_name()][prescriptionDict[child.get_name()].size() - 1][chosenMed]["Tag"] = 1
					else:
						var name = node.get_name() + "eonxeon"
						prescriptionDict[child.get_name()][prescriptionDict[child.get_name()].size() - 1][chosenMed][node.get_name()] = child.get_node(name + "/LineEdit").get_text()
						prescriptionDict[child.get_name()][prescriptionDict[child.get_name()].size() - 1][chosenMed]["Tag"] = 1
						
				elif node.get_class() == "HBoxContainer":
					var Min
					var Max
					if node.get_node("Min").is_visible():
						Min = node.get_node("Min").get_item_text(node.get_node("Min").get_selected())
					else:
						var name = node.get_node("Min").get_name() + "eonxeon"
						Min = node.get_node(name + "/LineEdit").get_text()
					
					if node.get_node("Max").is_visible():
						Max = node.get_node("Max").get_item_text(node.get_node("Max").get_selected())
					else:
						var name = node.get_node("Max").get_name() + "eonxeon"
						Max = node.get_node(name + "/LineEdit").get_text()
#						child.get_node(name + "/LineEdit").get_text()
					prescriptionDict[child.get_name()][prescriptionDict[child.get_name()].size() - 1][chosenMed][node.get_name()] = [Min, Max]
					
	elif currentType == "Infusions":
		$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid.hide()
		var children = $Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid.get_children()
		var drugsString = ""
		var infusionDrugArray = []
		if infusionDrugsAdded.size() > 0:
			for drug in infusionDrugsAdded:
				drugsString += drug
#			for node in get_node("PresDetails/FluidsAddScreen/DrugsAdded").get_children():
#				for drug in node.get_children():
#					infusionDrugArray.append(drug)
		prescriptionDict["Infusion"].append({(chosenMed + drugsString) : {}})
		prescriptionDict["Infusion"][prescriptionDict["Infusion"].size() - 1][chosenMed  + drugsString]["Tag"] = 1
		for node in children:
			if node.get_class() == "OptionButton":
				if node.is_visible():
					prescriptionDict["Infusion"][prescriptionDict["Infusion"].size() - 1][chosenMed  + drugsString][node.get_name()] = node.get_item_text(node.get_selected())
				else:
					var name = node.get_name() + "eonxeon"
					prescriptionDict["Infusion"][prescriptionDict["Infusion"].size() - 1][chosenMed  + drugsString][node.get_name()] = node.get_node("../" + name + "/LineEdit").get_text()
			
			elif node.get_class() == "HBoxContainer":
				var Min 
				var Max
				if node.get_node("Min").is_visible():
					Min = node.get_node("Min").get_item_text(node.get_node("Min").get_selected())
				else:
					var name = node.get_node("Min").get_name() + "eonxeon"
					Min = node.get_node(name + "/LineEdit").get_text()
				
				if node.get_node("Max").is_visible():
					Max = node.get_node("Max").get_item_text(node.get_node("Max").get_selected())
				else:
					var name = node.get_node("Max").get_name() + "eonxeon"
					Max = node.get_node(name + "/LineEdit").get_text()
				
				prescriptionDict["Infusion"][prescriptionDict["Infusion"].size() - 1][chosenMed  + drugsString][node.get_name()] = [Min, Max]

			elif node.get_class() == "VBoxContainer":
				if prescriptionDict["Infusion"][prescriptionDict["Infusion"].size() - 1][chosenMed  + drugsString].has("DrugsAdded") == false:
					prescriptionDict["Infusion"][prescriptionDict["Infusion"].size() - 1][chosenMed  + drugsString]["DrugsAdded"] = {}
				var drug = node.get_name()
				
				var doseMin
				var doseMax
				if node.get_node("Doses/Min").is_visible():
					doseMin = node.get_node("Doses/Min").get_item_text(node.get_node("Doses/Min").get_selected())
				else:
					var name = node.get_node("Doses/Min").get_name() + "eonxeon"
					doseMin = node.get_node("Doses/" + name + "/LineEdit").get_text()
				
				if node.get_node("Doses/Max").is_visible():
					doseMax = node.get_node("Doses/Max").get_item_text(node.get_node("Doses/Max").get_selected())
				else:
					var name = node.get_node("Doses/Max").get_name() + "eonxeon"
					doseMax = node.get_node("Doses/" + name + "/LineEdit").get_text()
				var dose = [doseMin, doseMax]
				
				var unit
				if node.get_node("Units").is_visible():
					unit = node.get_node("Units").get_item_text(node.get_node("Units").get_selected())
				else:
					var name = node.get_node("Units").get_name() + "eonxeon"
					unit = node.get_node(name + "/LineEdit").get_text()
					
				node.free()
				prescriptionDict["Infusion"][prescriptionDict["Infusion"].size() - 1][chosenMed  + drugsString]["DrugsAdded"][drug] = {"Dose": dose, "Unit": unit}
				
	elif currentType == "Oxygen":
		var children = $Container/Panel/Editor/ScrollContainer/MedicinesDetails/Oxygen.get_children()
		prescriptionDict["Oxygen"].append({chosenMed : {"Tag":1}})
		for node in children:
			if node.get_class() == "OptionButton":
				if node.is_visible():
					prescriptionDict["Oxygen"][prescriptionDict["Oxygen"].size() - 1][chosenMed][node.get_name()] = node.get_item_text(node.get_selected())
				else:
					var name = node.get_name() + "eonxeon"
					prescriptionDict["Oxygen"][prescriptionDict["Oxygen"].size() - 1][chosenMed][node.get_name()] = node.get_node("../" + name + "/LineEdit").get_text()
	print(prescriptionDict)
	print_prescribed_list()

func add_to_alternatives(): 
	print("adding to alternatives") 
	var children = $Container/Panel/Editor/ScrollContainer/MedicinesDetails.get_children()
	for child in children:
		if child.has_node("Label/CheckBox"):
			if child.get_node("Label/CheckBox").is_pressed():
				for i in range(0, prescriptionDict[presType].size()):
					if prescriptionDict[presType][i].has(chosenMed):
						prescriptionDict[presType][i][child.get_name()] = {}
						for node in child.get_children():
							if node.get_class() == "OptionButton":
								if node.is_visible():
									prescriptionDict[presType][i][child.get_name()][node.get_name()] = node.get_item_text(node.get_selected())
									prescriptionDict[presType][i][child.get_name()]["Tag"] = 0
								else:
									var name = node.get_name() + "eonxeon"
									prescriptionDict[presType][i][child.get_name()][node.get_name()] = child.get_node(name + "/LineEdit").get_text()
									prescriptionDict[presType][i][child.get_name()]["Tag"] = 0
							elif node.get_class() == "HBoxContainer":
								var Min
								var Max
								if node.get_node("Min").is_visible():
									Min = node.get_node("Min").get_item_text(node.get_node("Min").get_selected())
								else:
									var name = node.get_node("Min").get_name() + "eonxeon"
									Min = node.get_node(name + "/LineEdit").get_text()
								if node.get_node("Max").is_visible():
									Max = node.get_node("Max").get_item_text(node.get_node("Max").get_selected())
								else:
									var name = node.get_node("Max").get_name() + "eonxeon"
									Max = node.get_node(name + "/LineEdit").get_text()
								
								prescriptionDict[presType][i][child.get_name()][node.get_name()] = [Min, Max]


func print_prescribed_list():
	var container = "Container/Panel/PrescribedContainer/VBoxContainer/"
#	if currScreen == "PrescribeScreen":
#		container = "StoredPres/IxBg/ScrollContainer/VBoxContainer/"
#	elif currScreen == "InfoScreen":
#		container = "InfoScreen/PrescriptionsBg/ScrollContainer/VBoxContainer/"
	clear_prescribed_list(container)
	var printOrder = {"OnceOnly": ["Doses", "Routes"], "Regular": ["Doses", "Routes", "Frequency", "Duration"], "AsRequired": ["Doses", "Routes", "Frequency"], "Infusion": ["Volume", "Routes", "RunTime", "DrugsAdded"], "Oxygen": ["Flow Rate", "Target Sats", "Given"]}
	for type in prescriptionDict:
		if prescriptionDict[type].size() > 0:
			print(type)
			var bigLabel = return_big_label_node(type)
			get_node(container + type + "/BigLabelContainer").add_child(bigLabel)
			for dict in prescriptionDict[type]:
				for med in dict:
					print(med + " This")
					if dict[med]["Tag"] == 1:
						var node = preload("res://Scenes/PrescriptionButton.tscn").instance()
						node.set_name(med)
						node.get_node("TextureButton/Label").set_text(med)
						node.get_node("TextureButton/Cancel").connect("pressed", self, "remove_prescription", [node])
						if type == "Infusion":
							node.get_node("TextureButton/alt").hide()
						else:
							node.get_node("TextureButton/alt").connect("pressed", self, "open_alternative_screen", [node])
						
						for detail in printOrder[type]:
							var detailCont = return_detail_frame_node(detail)
							if detail != "DrugsAdded":
								if detail == "Doses":
									var Min = detail[0]
									var Max = detail[1]
									if Min == Max:
										detailCont.get_node("detailText").set_text(dict[med][detail][0] + " " + dict[med]["Units"])
									else:
										detailCont.get_node("detailText").set_text(dict[med][detail][0] + " - " + dict[med][detail][1] + " " + dict[med]["Units"])
								elif detail == "Duration":
									detailCont.get_node("detailText").set_text(dict[med][detail] + " " + dict[med]["DurUnits"])
								elif detail == "Volume":
									var Min = detail[0]
									var Max = detail[1]
									detailCont.get_node("detailText").set_text(dict[med][detail][0] + " - " + dict[med][detail][1] + " " + dict[med]["VolUnits"])
#									detailCont.get_node("detailText").set_text(dict[med][detail] + " " + dict[med]["VolUnits"])
								elif detail == "RunTime":
									var Min = detail[0]
									var Max = detail[1]
									detailCont.get_node("detailText").set_text(dict[med][detail][0] + " - " + dict[med][detail][1] + " " + dict[med]["RunTimeUnits"])
#									detailCont.get_node("detailText").set_text(dict[med][detail] + " " + dict[med]["RunTimeUnits"])
								else:
									detailCont.get_node("detailText").set_text(dict[med][detail])
								node.get_node("DetailsContainer").add_child(detailCont)
							
							elif detail == "DrugsAdded":
								if dict[med].has(detail):
									node.get_node("TextureButton/alt").hide()
									node.get_node("DrugsAddedContainer").show()
									var displayString = med
									for drug in dict[med][detail]:
										var detailCont2 = return_detail_frame_node(detail)
										var dose
										if int(dict[med][detail][drug]["Dose"][0]) == int(dict[med][detail][drug]["Dose"][1]):
											dose = dict[med][detail][drug]["Dose"][0]
										else:
											dose = dict[med][detail][drug]["Dose"][0] + " - " + dict[med][detail][drug]["Dose"][1]
										detailCont2.get_node("detailText").set_text("+ " + drug + " " + dose + dict[med][detail][drug]["Unit"])
										node.get_node("DrugsAddedContainer").add_child(detailCont2)
										displayString = displayString.replace(drug, "")
									node.get_node("TextureButton/Label").set_text(displayString)
						get_node(container + type + "/PresConatiner").add_child(node)

func return_big_label_node(type):
	var colourDict = {"OnceOnly": Color(0.992188, 0.553291, 0.127899, 1), "Regular": Color(0.070312, 1, 0.084839, 1), "AsRequired": Color(0.175781, 0.6716, 1, 1), "Infusion": Color(1, 0.179688, 0.987183, 1), "Oxygen": Color(1, 1, 1, 1)}
	var bigLabel = NinePatchRect.new()
	bigLabel.set_texture(preload("res://Graphics/presSideButton.png"))
	bigLabel.set_v_size_flags(3)
	bigLabel.set_patch_margin(MARGIN_LEFT, 10)
	bigLabel.set_patch_margin(MARGIN_TOP, 10)
	bigLabel.set_patch_margin(MARGIN_BOTTOM, 10)
	bigLabel.set_patch_margin(MARGIN_RIGHT, 5)
	bigLabel.set_custom_minimum_size(Vector2(40, 63))
	bigLabel.set_modulate(colourDict[type])
	bigLabel.set_name("bigLabel")
	return bigLabel

func return_detail_frame_node(detail):
	var detailsCont = NinePatchRect.new()
	detailsCont.set_texture(preload("res://Graphics/baseDataContainer.png"))
	detailsCont.set_h_size_flags(3)
	detailsCont.set_patch_margin(MARGIN_LEFT, 8)
	detailsCont.set_patch_margin(MARGIN_TOP, 8)
	detailsCont.set_patch_margin(MARGIN_BOTTOM, 8)
	detailsCont.set_patch_margin(MARGIN_RIGHT, 8)
	detailsCont.set_self_modulate(Color(0.191406,0.191406,0.191406))
	detailsCont.set_name(detail)
	var label = Label.new()
	label.set_clip_text(true)
	label.set_valign(1)
	label.set_align(1)
	label.set_margin(MARGIN_BOTTOM, 0)
	label.set_margin(MARGIN_TOP, 0)
	label.set_margin(MARGIN_LEFT, 5)
	label.set_margin(MARGIN_RIGHT, 5)
	label.set_anchor(MARGIN_RIGHT, ANCHOR_END)
	label.set_anchor(MARGIN_BOTTOM, ANCHOR_END)
	label.set_name("detailText")
#	label.add_font_override("font", preload("res://Fonts/Nunito_reg_16.font"))
	detailsCont.add_child(label)
	return detailsCont

func clear_prescribed_list(container):
	for type in prescriptionDict:
		for label in get_node(container + type + "/BigLabelContainer").get_children():
			label.free()
		for prescribed in get_node(container + type + "/PresConatiner").get_children():
			prescribed.free()
			
func add_infusion_drug_pressed():
	$Container/Panel/NinePatchRect/Types.hide()
	$Container/Panel/NinePatchRect/Label.show()
	$Container/Panel/NinePatchRect/Label.set_text("INFUSION DRUGS")
	$Container/Panel/NinePatchRect/ScrollContainer.margin_bottom = -38
	$Container/Panel/Editor/HBoxContainer.hide()
	$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid/AddDrug.hide()
	$Container/Panel/NinePatchRect.set_self_modulate(Color(0.484375,0.484375,0.484375))
	form_search_array(medicines["Medications"], true)
	$Container/Panel/NinePatchRect/InfDone.show()


#Plan is to have a done button at the bottom so calling or emitting isn't an issue. 
func infusion_chosen(button):
	currentType = "Medications"
	var node = preload("res://Scenes/InfusionDrugBox.tscn").instance()
	node.get_node("Drug").set_text(button.get_name())
	node.set_name(button.get_name())
	set_option_button_data(node, button.get_name())
	infusionDrugsAdded.append(button.get_name())
	$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid.add_child(node)

func close_infusion_list():
	currentType = "Infusions"
	$Container/Panel/NinePatchRect/Types.show()
	$Container/Panel/NinePatchRect/Label.hide()
	$Container/Panel/NinePatchRect/InfDone.hide()
	$Container/Panel/Editor/HBoxContainer.show()
	$Container/Panel/NinePatchRect/ScrollContainer.margin_bottom = 0
	$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid.move_child($Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid/AddDrug, $Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid.get_child_count())
	$Container/Panel/Editor/ScrollContainer/MedicinesDetails/Fluid/AddDrug.show()
	$Container/Panel/NinePatchRect.set_self_modulate(Color(0.863281,0.863281,0.863281))
	form_search_array(medicines[currentType], false)


func open_alternative_screen(btn):
	altPres = true
	presType = btn.get_node("../..").get_name()
#	print("The type is " + currType)
	chosenMed = btn.get_name()
#	singleton.clear_container(get_node("PresDetails/AltAddScreen/Container"))
#	get_node("PresDetails").set_size(Vector2(get_node("PresDetails").get_size().x, 200))
#	get_node("PresDetails/AltAddScreen").show()
#	get_node("PresDetails/MedsAddScreen").hide()
#	get_node("PresDetails/FluidsAddScreen").hide()
#	get_node("PresDetails").show()
#	get_node("PresDetails/Title").set_text(currentMed + " Alternatives")
	$Container/Panel/PrescribedContainer.hide()
	$Container/Panel/Editor.show()
	if medicines["Medications"][chosenMed].has("Alternatives"):
		var alternatives = medicines["Medications"][chosenMed]["Alternatives"]
		for alt in alternatives:
			var node = load("res://Scenes/" + presType + ".tscn").instance()
			node.get_node("Label/CheckBox").show()
			node.get_node("Label/CheckBox").connect("pressed", self, "alternative_check_box_pressed", [node.get_node("Label/CheckBox"), node])
			for child in node.get_children():
				if child.get_class() != "Label":
					child.hide()
			node.get_node("Label").set_text(alt + ":")
			node.set_name(alt)
			$Container/Panel/Editor/ScrollContainer/MedicinesDetails.add_child(node)
			set_option_button_data(node, alt)

func alternative_check_box_pressed(checkBox, node):
	if checkBox.is_pressed():
		for child in node.get_children():
			if child.get_class() != "Label":
					child.show()
	else:
		for child in node.get_children():
			if child.get_class() != "Label":
				child.hide()

func add_procedure_pressed():
	$ScenarioDetails/Procedures.hide()
	$ScenarioDetails/ProceduresSearch.show()
	$ScenarioDetails/None.hide()
	add_to_vbox_search(proceduresSearchArray, $ScenarioDetails/ProceduresSearch/Search/VBoxContainer, 0)

func add_to_vbox_search(array, cont, type):
	singleton.clear_container(cont)
	for item in array:
		var button = Button.new()
		button.set_text(item)
		button.set_name(item)
		if type == 0:
			button.connect("pressed", self, "procedure_chosen", [button])
		else:
			button.connect("pressed", self, "call_chosen", [button])
		cont.add_child(button)

func procedure_chosen(button):
	$ScenarioDetails/Procedures.show()
	$ScenarioDetails/ProceduresSearch.hide()
	var procedure = button.get_name()
	if proceduresChange == null:
		proceduresChange = {}
	if proceduresChange.has(procedure) == false:
		proceduresChange[procedure] = procedures[procedure]["Detail"]
		add_procedure(procedure)

func add_procedure(procedure):
	var node = load("res://Scenes/interactionEdit.tscn").instance()
	node.get_node("Label").set_text(procedure)
	node.set_name(procedure)
	node.get_node("Edit").set_text(procedures[procedure]["Detail"])
	node.get_node("Edit").connect("text_changed", self, "procedures_text_changed", [node])
	node.get_node("remove").connect("pressed", self, "remove_procedure", [node])
	$ScenarioDetails/Procedures/VBoxContainer.add_child(node)
	

func remove_procedure(node):
	proceduresChange.erase(node.get_name())
	node.free()

func procedures_text_changed(node):
	var text = node.get_node("Edit").get_text()
	proceduresChange[node.get_name()] = text
	print(proceduresChange)

func add_contacts_pressed():
	$Contacts/Calls.hide()
	$Contacts/CallsSearch.show()
	$Contacts/None.hide()
	add_to_vbox_search(callsSearchArray, $Contacts/CallsSearch/Search/VBoxContainer, 1)

func call_chosen(button):
	$Contacts/Calls.show()
	$Contacts/CallsSearch.hide()
	var call = button.get_name()
	if calls == null:
		calls = []
	if calls.has(call) == false:
		calls.append(call)
		add_call(call)

func add_call(call):
	var node = load("res://Scenes/CorrectQ.tscn").instance()

	node.get_node("Question").set_text(call)
	node.set_name(call)
	node.get_node("Close").connect("pressed", self, "remove_call", [node])
	$Contacts/Calls/VBoxContainer.add_child(node)

func remove_call(node):
	calls.erase(node.get_name())
	node.free()

func load_management_data():
	print_prescribed_list()
	print("calls = " + str(calls))
	if calls != null:
		for call in calls:
			add_call(call)
	if proceduresChange != null:
		for pro in proceduresChange:
			print(pro)
			add_procedure(pro)

func check_if_other(ID, optionButton):
	if optionButton.get_item_text(ID) == "Other":
		optionButton.hide()
		var pos = optionButton.get_position_in_parent()
		var name = optionButton.get_name()
		var placeholder = optionButton.get_node("Label").get_text()
		var parent = optionButton.get_parent()
		var otherNode = load("res://Scenes/nodeForOther.tscn").instance()
		otherNode.set_name(name + "eonxeon")
		otherNode.get_node("remove").connect("pressed", self, "cancel_other_node", [otherNode])
		print(name)
		if "Min" in name || "Max" in name:
			otherNode.get_node("LineEdit").connect("text_changed", self, "edit_node_text_entered", [otherNode, true])
		otherNode.get_node("LineEdit").set_placeholder(placeholder)
		parent.add_child(otherNode)
		parent.move_child(otherNode, pos)

func edit_node_text_entered(text, node, Integer):
	print(text)
	if Integer == true:
		if text.is_valid_integer():
			node.set_self_modulate(Color(0.145098,0.145098,0.145098))
		else:
			node.set_self_modulate(Color(0.398438,0.024902,0.024902))



func cancel_other_node(otherNode):
	var optionBtnName = otherNode.get_name().replace("eonxeon", "")
	var optionButton = otherNode.get_parent().get_node(optionBtnName)
	optionButton.show()
	optionButton.select(0)
	optionButton.get_node("Label").show()
	otherNode.free()