extends Container

# class member variables go here, for example:
# var a = 2
var botQuestions
var responseDict = {}
var correctDict = {}
var toEditNum = 0

func _ready():
	$MainPatch/Buttons/Edit.connect("pressed", self, "edit_button_pressed")
	$MainPatch/Buttons/Test.connect("pressed", self, "test_button_pressed")
	$MainPatch/Buttons/Search.connect("pressed", self, "search_button_pressed")
	$MainPatch/SearchScreen/SearchButton.connect("pressed", self, "search_q_button_pressed")
	$MainPatch/EditScreen/AddTemplate.connect("pressed", self, "open_template_screen")
	$TemplateScreen/Panel/HBoxContainer/AddSelected.connect("pressed", self, "add_selected_temp_qs")
	$TemplateScreen/Panel/HBoxContainer/AddAll.connect("pressed", self, "add_all_temp_qs")
	$TemplateScreen/Exit.connect("pressed", self, "exit_template_screen")
	botQuestions = singleton.load_file_as_JSON("res://JSON_files/botQuestions.json")
	
	var data = get_node("../..").scenarioDict
	if data.has("History"):
		responseDict = data["History"]
		correctDict = data["Answers"]["History"]
		load_history_data()

func edit_button_pressed():
	if $MainPatch/EditScreen.is_visible() == false:
		$MainPatch/EditScreen.show()
		$MainPatch/TestScreen.hide()
		$MainPatch/SearchScreen.hide()
		$MainPatch/EditScreen/CanvasLayer/InnerShadow.show()
		$MainPatch/EditScreen/CanvasLayer/InnerShadow.margin_top = 157
		$MainPatch/Buttons/Edit/TextureRect.hide()
		toEditNum = 0

func test_button_pressed():
	if $MainPatch/TestScreen.is_visible() == false:
		$MainPatch/TestScreen.show()
		$MainPatch/EditScreen.hide()
		$MainPatch/SearchScreen.hide()
		$MainPatch/EditScreen/CanvasLayer/InnerShadow.hide()
		save_responses()
		$MainPatch/TestScreen/pixelBotBox.diction = responseDict
		

func search_button_pressed():
	if $MainPatch/SearchScreen.is_visible() == false:
		$MainPatch/SearchScreen.show()
		$MainPatch/TestScreen.hide()
		$MainPatch/EditScreen.hide()
		$MainPatch/EditScreen/CanvasLayer/InnerShadow.show()
		$MainPatch/EditScreen/CanvasLayer/InnerShadow.margin_top = 187

func search_questions():
	singleton.clear_container($MainPatch/SearchScreen/TextureRect2/ScrollContainer/VBoxContainer)
	var text = $MainPatch/SearchScreen/Search.get_text()
	for q in botQuestions["Questions"]:
		if text.to_lower() in q.to_lower():
			add_search_question(q)
		elif botQuestions["Questions"][q]["Tags"] != null:
			if botQuestions["Questions"][q]["Tags"].has(text.to_lower()):
				add_search_question(q)

func add_search_question(q):
	var box = preload("res://Scenes/SearchQBox.tscn").instance()
	box.get_node("Question").set_text(q)
	box.set_name(q)
	box.get_node("Edit").connect("pressed", self, "edit_question_pressed", [box.get_name()])
	box.get_node("Correct").connect("pressed", self, "add_correct_pressed", [box.get_name()])
	$MainPatch/SearchScreen/TextureRect2/ScrollContainer/VBoxContainer.add_child(box)

func search_q_button_pressed():
	search_questions()

func edit_question_pressed(q):
	if $MainPatch/EditScreen/TextureRect/ScrollContainer/VBoxContainer.has_node(q) == false:
		add_edit_q_box(q)


func add_edit_q_box(q, loaded = null):
	var box = preload("res://Scenes/ReplyEdit.tscn").instance()
	box.get_node("Question").set_text(q)
	box.set_name(q)
	box.get_node("Close").connect("pressed", self, "remove_reply_edit", [box])
	toEditNum += 1
	if loaded != null:
		box.get_node("Response").set_text(loaded)
	else:
		box.get_node("Response").set_text(botQuestions["Questions"][q]["Response"])
		$MainPatch/Buttons/Edit/TextureRect.show()
		$MainPatch/Buttons/Edit/TextureRect/Label.set_text(str(toEditNum))
	$MainPatch/EditScreen/TextureRect/ScrollContainer/VBoxContainer.add_child(box)

func remove_reply_edit(box):
	box.free()
	
func add_correct_pressed(q):
	if $CorrectQs/ScrollContainer/VBoxContainer.has_node(q) == false:
		add_correct(q)

func add_correct(q):
	var box = preload("res://Scenes/CorrectQ.tscn").instance()
	box.get_node("Question").set_text(q)
	box.set_name(q)
	box.get_node("Close").connect("pressed", self, "remove_reply_edit", [box])
	$CorrectQs/ScrollContainer/VBoxContainer.add_child(box)

func save_history_data():
	save_responses()
	save_correct()

func save_responses():
	for node in $MainPatch/EditScreen/TextureRect/ScrollContainer/VBoxContainer.get_children():
		responseDict[node.get_name()] = node.get_node("Response").get_text()

func save_correct():
	var cont = $CorrectQs/ScrollContainer/VBoxContainer
	for i in range(1, cont.get_child_count()):
		correctDict[cont.get_child(i).get_name()] = cont.get_child(i).get_node("Question").get_text()

func load_history_data():
	for q in correctDict:
		add_correct(correctDict[q])
	for q in responseDict:
		add_edit_q_box(q, responseDict[q])
	toEditNum = 0

func open_template_screen():
	$MainPatch/EditScreen/CanvasLayer/InnerShadow.hide()
	$TemplateScreen.show()
	update_template_list(botQuestions["Templates"])

var chosenTemp = null
func update_template_list(array):
	var container = get_node("TemplateScreen/Panel/NinePatchRect/Templates/VBoxContainer")
	singleton.clear_container(container)
	for template in array:
		var button = template_button_return(template)
		button.connect("pressed", self, "template_chosen", [button])
		if template == chosenTemp:
			button.set_pressed(true)
		container.add_child(button)
	container.get_node("..").set_v_scroll(0)

func template_button_return(template):
	var button = TextureButton.new()
	button.texture_normal = load("res://Graphics/IxButton.png")
	button.texture_hover = load("res://Graphics/IxButtonHover.png")
	button.texture_pressed = load("res://Graphics/IxButtonPressed.png")
	button.toggle_mode = true
	button.set_name(template)
	
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
	label.set_text(template)
	button.add_child(label)
	
	return button

func template_chosen(button):
	if chosenTemp != null:
		$TemplateScreen/Panel/NinePatchRect/Templates/VBoxContainer.get_node(chosenTemp).set_pressed(false)
	chosenTemp = button.get_name()
	singleton.clear_container($TemplateScreen/Panel/NinePatchRect/Questions/VBoxContainer)
#	var template = button.get_name()
	for q in botQuestions["Questions"]:
		if botQuestions["Questions"][q]["Templates"] != null:
			if botQuestions["Questions"][q]["Templates"].has(chosenTemp):
				add_template_q(q)

func add_template_q(q):
	var button = load("res://Scenes/TemplateQ.tscn").instance()
	button.set_name(q)
	button.get_node("Label").set_text(q)
	button.connect("pressed", self, "template_question_pressed", [button])
	$TemplateScreen/Panel/NinePatchRect/Questions/VBoxContainer.add_child(button)

func template_question_pressed(button):
	if button.is_pressed():
		button.get_node("Tick").show()
	else:
		button.get_node("Tick").hide()

func add_selected_temp_qs():
	for child in $TemplateScreen/Panel/NinePatchRect/Questions/VBoxContainer.get_children():
		if child.is_pressed():
			edit_question_pressed(child.get_name())
	$MainPatch/EditScreen/CanvasLayer/InnerShadow.show()
	$TemplateScreen.hide()
	chosenTemp = null
	
func add_all_temp_qs():
	for child in $TemplateScreen/Panel/NinePatchRect/Questions/VBoxContainer.get_children():
		edit_question_pressed(child.get_name())
	$MainPatch/EditScreen/CanvasLayer/InnerShadow.show()
	$TemplateScreen.hide()
	chosenTemp = null

func exit_template_screen():
	$MainPatch/EditScreen/CanvasLayer/InnerShadow.show()
	$TemplateScreen.hide()
	chosenTemp = null

#label.connect("item_rect_changed", self, "on_item_rect_changed", [label])

#node.get_node("Container").connect("resized", self, "VBox_Resized", [node.get_node("Container")])

#func VBox_Resized(vbox):
#	print(vbox.get_size().y)
#	vbox.get_node("..").rect_min_size =  (Vector2(vbox.get_node("..").get_size().x, vbox.get_size().y + 79))
