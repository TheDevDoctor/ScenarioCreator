extends Container

var ixDict
var ixSearchArray = []
var chosenIx = "Null"
var ixChange = {"LIST": {}, "IMAGING": {}}
var correctIx = []

func _ready():
	ixDict = singleton.load_file_as_JSON("res://JSON_files/investigations.json")
	for type in ixDict:
		for ix in ixDict[type]:
			ixSearchArray.append(ix)
	ixSearchArray.sort()
	update_ix_list(ixSearchArray)
	$Container/Panel/HBoxContainer/Edit.connect("pressed", self, "edit_button_pressed")
	$Container/Panel/NinePatchRect/Search.connect("text_changed", self, "search_text_changed")
	$Container/Panel/HBoxContainer/Correct.connect("pressed", self, "add_to_correct_pressed")
	
	var data = get_node("../..").scenarioDict
	if data.has("Investigations"):
		correctIx = data["Answers"]["Investigations"]
		ixChange = data["Investigations"]
		load_investigation_data()


func search_text_changed(text):
	var array = []
	if text.length() > 0:
		for ix in ixSearchArray:
			if text.to_lower() in ix.to_lower():
				array.append(ix)
		update_ix_list(array)
	else:
		update_ix_list(ixSearchArray)

func update_ix_list(array):
	var container = get_node("Container/Panel/NinePatchRect/ScrollContainer/VBoxContainer")
	singleton.clear_container(container)
	for ix in array:
		var button = ix_button_return(ix)
		button.connect("pressed", self, "ix_chosen", [button])
		if ix == chosenIx:
			button.set_pressed(true)
		container.add_child(button)
	container.get_node("..").set_v_scroll(0)

func ix_button_return(ix):
	var button = TextureButton.new()
	button.texture_normal = load("res://Graphics/IxButton.png")
	button.texture_hover = load("res://Graphics/IxButtonHover.png")
	button.texture_pressed = load("res://Graphics/IxButtonPressed.png")
	button.toggle_mode = true
	button.set_name(ix)
	
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
	label.set_text(ix)
	button.add_child(label)
	
	return button

func ix_chosen(button):
	if chosenIx != null:
		if $Container/Panel/NinePatchRect/ScrollContainer/VBoxContainer.has_node(chosenIx):
			$Container/Panel/NinePatchRect/ScrollContainer/VBoxContainer.get_node(chosenIx).set_pressed(false)
	chosenIx = button.get_name()
	print_ix_values()
	
func print_ix_values():
	for type in ixDict:
		if ixDict[type].has(chosenIx):
			if type == "LIST":
				print_list_values(ixDict[type][chosenIx], chosenIx)
			elif type == "IMAGING":
				print_imaging_values(ixDict[type][chosenIx], chosenIx)

func print_list_values(data, ix):
	get_node("Container/Panel/ScrollContainer").show()
	get_node("Container/Panel/ImagingContainer").hide()
	var containers = get_node("Container/Panel/ScrollContainer/PrintIxContainer").get_children()
	var array = ["Name", "Value", "Range", "Unit"]
	for i in range(4):
		for child in containers[i].get_children():
			child.free()
		var box = return_print_ix_box(array[i], array[i], Color(0.070312,0.070312,0.070312))
		box.set_self_modulate(Color(0.070312,0.070312,0.070312))
#		box.get_node("detailText").add_font_override("font", preload("res://Fonts/nunito_reg_20.font"))
		containers[i].add_child(box)

	for detail in data["Order"]:
		var color = Color(0.037933,0.29956,0.441406)
		var value
		print(ixChange)
		if ixChange["LIST"].has(ix):
			if ixChange["LIST"][ix].has(detail):
				value = return_print_ix_box(str(ixChange["LIST"][ix][detail]), detail, color)
			else:
				value = return_print_ix_box(str(data["Data"][detail][0]), detail, color)
		else:
			value = return_print_ix_box(str(data["Data"][detail][0]), detail, color)
		var name = return_print_ix_box(detail, null, color)
		containers[0].add_child(name)
		containers[1].add_child(value)
		var ixRange = return_print_ix_box(data["Data"][detail][1], null, color)
		containers[2].add_child(ixRange)
		var unit = return_print_ix_box(data["Data"][detail][2], null, color)
		containers[3].add_child(unit)

func print_imaging_values(data, ix):
	get_node("Container/Panel/ImagingContainer").show()
	get_node("Container/Panel/ScrollContainer").hide()
	get_node("Container/Panel/ImagingContainer/VBoxContainer/TextureRect").set_texture(load("res://Graphics/Images/" + data["Data"][0]))
	if ixChange["IMAGING"].has(ix):
		get_node("Container/Panel/ImagingContainer/VBoxContainer/Findings").set_text(ixChange["IMAGING"][ix]["Findings"])
		get_node("Container/Panel/ImagingContainer/VBoxContainer/FindingsLabel").set_text(ixChange["IMAGING"][ix]["Findings"])
		get_node("Container/Panel/ImagingContainer/VBoxContainer/Impression").set_text(ixChange["IMAGING"][ix]["Impression"])
		get_node("Container/Panel/ImagingContainer/VBoxContainer/ImpressionLabel").set_text(ixChange["IMAGING"][ix]["Impression"])
	else:
		get_node("Container/Panel/ImagingContainer/VBoxContainer/Findings").set_text(data["Data"][2])
		get_node("Container/Panel/ImagingContainer/VBoxContainer/FindingsLabel").set_text(data["Data"][2])
		get_node("Container/Panel/ImagingContainer/VBoxContainer/Impression").set_text(data["Data"][3])
		get_node("Container/Panel/ImagingContainer/VBoxContainer/ImpressionLabel").set_text(data["Data"][3])

func return_print_ix_box(text, name, color):
	var detailsCont = NinePatchRect.new()
	detailsCont.set_texture(preload("res://Graphics/baseDataContainer.png"))
	detailsCont.set_h_size_flags(3)
	detailsCont.set_patch_margin(MARGIN_LEFT, 5)
	detailsCont.set_patch_margin(MARGIN_TOP, 5)
	detailsCont.set_patch_margin(MARGIN_BOTTOM, 5)
	detailsCont.set_patch_margin(MARGIN_RIGHT, 5)
	detailsCont.set_custom_minimum_size(Vector2(0, 32))
	if name != null:
		detailsCont.set_name(name)
	detailsCont.set_self_modulate(color)
	
	var label = Label.new()
	label.set_clip_text(true)
	label.set_valign(1)
#	label.set_align(1)
	label.set_margin(MARGIN_BOTTOM, 0)
	label.set_margin(MARGIN_TOP, 2)
	label.set_margin(MARGIN_LEFT, 10)
	label.set_margin(MARGIN_RIGHT, -5)
	label.set_anchor(MARGIN_RIGHT, ANCHOR_END)
	label.set_anchor(MARGIN_BOTTOM, ANCHOR_END)
	label.set_name("detailText")
	label.set_text(text)
	detailsCont.add_child(label)
	
	return detailsCont

func edit_button_pressed():
	if $Container/Panel/HBoxContainer/Edit.get_text() == "Edit":
		set_up_editing()
		$Container/Panel/HBoxContainer/Edit.set_text("Update")
	else:
		update_to_edits()
		$Container/Panel/HBoxContainer/Edit.set_text("Edit")

func set_up_editing():
	if get_node("Container/Panel/ScrollContainer").is_visible() == true:
		for child in get_node("Container/Panel/ScrollContainer/PrintIxContainer/VBoxContainer1").get_children():
			var value = child.get_node("detailText").get_text()
			if value != "Value":
				child.get_node("detailText").free()
				var lineEdit = LineEdit.new()
				lineEdit.set_anchor(MARGIN_RIGHT, ANCHOR_END)
				lineEdit.set_anchor(MARGIN_BOTTOM, ANCHOR_END)
				lineEdit.set_margin(MARGIN_BOTTOM, -3)
				lineEdit.set_margin(MARGIN_TOP, 8)
				lineEdit.set_margin(MARGIN_LEFT, 10)
				lineEdit.set_margin(MARGIN_RIGHT, -10)
				lineEdit.set_text(value)
				lineEdit.set_name("detailText")
#				lineEdit.add_style_override("normal", StyleBoxEmpty.new())
#				lineEdit.add_style_override("focus", StyleBoxEmpty.new())
				child.add_child(lineEdit)
				lineEdit.get_node("..").set_self_modulate(Color(0.214844,0.214844,0.214844))
	elif get_node("Container/Panel/ImagingContainer").is_visible() == true:
		$Container/Panel/ImagingContainer/VBoxContainer/FindingsLabel.hide()
		$Container/Panel/ImagingContainer/VBoxContainer/Findings.show()
		$Container/Panel/ImagingContainer/VBoxContainer/ImpressionLabel.hide()
		$Container/Panel/ImagingContainer/VBoxContainer/Impression.show()

func update_to_edits():
	if get_node("Container/Panel/ScrollContainer").is_visible() == true:
		for child in get_node("Container/Panel/ScrollContainer/PrintIxContainer/VBoxContainer1").get_children():
			if child.get_name() != "Value":
				var text = child.get_node("detailText").get_text()
				if str(ixDict["LIST"][chosenIx]["Data"][child.get_name()][0]) != text:
					add_to_ix_change_dict(child.get_name(), text, 0)
				child.get_node("detailText").free()
				var label = Label.new()
				label.set_clip_text(true)
				label.set_valign(1)
				label.set_margin(MARGIN_BOTTOM, 0)
				label.set_margin(MARGIN_TOP, 2)
				label.set_margin(MARGIN_LEFT, 10)
				label.set_margin(MARGIN_RIGHT, 5)
				label.set_anchor(MARGIN_RIGHT, ANCHOR_END)
				label.set_anchor(MARGIN_BOTTOM, ANCHOR_END)
				label.set_name("detailText")
				label.set_text(text)
				child.add_child(label)
				label.get_node("..").set_self_modulate(Color(0.037933,0.29956,0.441406))
	elif get_node("Container/Panel/ImagingContainer").is_visible() == true:
		var findings = $Container/Panel/ImagingContainer/VBoxContainer/Findings.get_text()
		var impression = $Container/Panel/ImagingContainer/VBoxContainer/Impression.get_text()
		$Container/Panel/ImagingContainer/VBoxContainer/FindingsLabel.set_text(findings)
		$Container/Panel/ImagingContainer/VBoxContainer/ImpressionLabel.set_text(impression)
		
		$Container/Panel/ImagingContainer/VBoxContainer/FindingsLabel.show()
		$Container/Panel/ImagingContainer/VBoxContainer/Findings.hide()
		$Container/Panel/ImagingContainer/VBoxContainer/ImpressionLabel.show()
		$Container/Panel/ImagingContainer/VBoxContainer/Impression.hide()

		if ixDict["IMAGING"][chosenIx]["Data"][2] != findings || ixDict["IMAGING"][chosenIx]["Data"][3] != impression:
			add_to_ix_change_dict(findings, impression, 1)

func add_to_ix_change_dict(val1, val2, type):
#	var dict = {"LIST": {}, "IMAGING": {}} #get_node("/root/MainScreen/Patch9Frame/CONTAINER/ScenarioCreator").IxChange
	if type == 0:
		if ixChange["LIST"].has(chosenIx) == false:
			ixChange["LIST"][chosenIx] = {}
		ixChange["LIST"][chosenIx][val1] = val2
	elif type == 1:
		if ixChange["IMAGING"].has(chosenIx) == false:
			ixChange["IMAGING"][chosenIx] = {}
		ixChange["IMAGING"][chosenIx]["Findings"] = val1
		ixChange["IMAGING"][chosenIx]["Impression"] = val2
		ixChange["IMAGING"][chosenIx]["Image"] = "imageLink"

func add_to_correct_pressed():
	add_to_correct(chosenIx)


func add_to_correct(ix):
	if $Correct/ScrollContainer/VBoxContainer.has_node(ix) == false:
		var node = preload("res://Scenes/CorrectQ.tscn").instance()
		node.get_node("Question").set_text(ix)
		node.get_node("Close").connect('pressed', self, 'remove_correct_ix', [node])
		node.set_name(ix)
		$Correct/ScrollContainer/VBoxContainer.add_child(node)
		if correctIx.has(ix) == false:
			correctIx.append(ix)

func remove_correct_ix(node):
	correctIx.erase(node.get_name())
	node.free()

func load_investigation_data():
	for ix in correctIx:
		add_to_correct(ix)
