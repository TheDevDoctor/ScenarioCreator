extends Node

signal dialogue_done

var currentStory = {}

var dialogueBoxLabel
var speakingLabel
var replyBox
var textEntry
var branch
var divert
var currentBranch
var interaction
var score = 0
var dialogueOpen = false
var replyToOpen = false
var canInteract = false
var toEnd = false
var bedStory = false
#var pos_ext_set = false
var yAxis
var xAxis
var zoomedIn = false

var currentBranchNum = 0

func _ready():
	set_process_input(true)
	
	get_node("../playerNode/Player").connect("zoomed_in", self, "zoomed_in_pos")
	get_node("../playerNode/Player").connect("zoomed_out", self, "zoomed_out_pos")

func _input(event):
#	print("input")
	if dialogueOpen == true && canInteract == true:
		if event.is_action_pressed("ui_interact"):
			set_next()

func zoomed_in_pos():
	zoomedIn = true

func zoomed_out_pos():
	zoomedIn = false


func reset_params(target):
	toEnd = false
	replyToOpen = false
	canInteract = true
	bedStory = false

	score = 0
	var box = preload("res://Scenes/DialogueBox.tscn").instance()
	get_node("../GUI").add_child(box)
	
	var root = get_node("..")
	dialogueBoxLabel = root.get_node("GUI/DialogueBox/Dialogue/Text")
	speakingLabel = root.get_node("GUI/DialogueBox/Dialogue/Speaking/Text")
	replyBox = root.get_node("GUI/DialogueBox/Reply")
	replyBox.get_node("TextEntry/Button").connect("pressed", self, "input_text")
	replyBox.get_node("TextEntry/LineEdit").connect("text_changed", self, "line_edit_text_changed")
	replyBox.hide()
	set_reply_box_pos(target)

func set_reply_box_pos(target):
	replyBox.set_size(Vector2(500, replyBox.get_size().y))
	if zoomedIn == true:
		yAxis = float(130)
		replyBox.get_node("Left").hide()
		xAxis = 70
	else:
		yAxis = float(60)
		if target.get_class() != "Node":
			if target.get_position().x > get_node("/root/World/playerNode/Player").get_position().x:
				xAxis = 20
				replyBox.get_node("Left").hide()
			elif target.get_position().x < get_node("/root/World/playerNode/Player").get_position().x:
				xAxis = 690
				replyBox.get_node("Right").hide()
		else:
			xAxis = 20
	
func init_chat_dialogue(target, b):
	reset_params(target)
	var dialogue = {}
	dialogue = get_node("/root/singleton").load_file_as_JSON("res://JSON_files/character_dialogue.json")
	interaction = target.get_name()
	branch = dialogue[interaction][b]
	var first = branch["Start"] 
	set_first(first)

var bed_phrases = {}
var caller = null
func init_call_dialogue(target):
	reset_params(target)

	interaction = target.get_name()
	caller = $"..".calls[interaction]
	
	var callInteractions = singleton.load_file_as_JSON("res://JSON_files/bleepInteractions.json")
	branch = callInteractions[caller]
	$"..".calls.erase(interaction)
	replyBox.get_node("Left").hide()
	var first = branch["Start"] 
	set_first(first)
	var bedStories = {"BED1": $"/root/MainFrame".scenarioDict}
	for bed in bedStories:
		if bedStories[bed] != null:
			var string = "Could you please come and see " +  bedStories[bed]["PatientDetails"]["Forename"] + " " + bedStories[bed]["PatientDetails"]["Surname"] + " in bed " + bed.replace("BED", "") + "."
			bed_phrases[bed] = string
			print(string)
	xAxis = 120

func init_patient_dialogue(target):
	#reset params:
	reset_params(target)
	interaction = target.get_name()
	bedStory = true
	#set story needed to be parsed:
	currentStory =  $"/root/MainFrame".scenarioDict#get_node("/root/singleton").bedStories[get_node("/root/singleton").currentWard][interaction][0]
	#get the current branch and first text:
	branch = currentStory["Story"][get_branch_to_play($"..".bedStoryArray[0])]
	var first = branch["Start"] 
	set_first(first)

func set_first(first):
	#set first text:
	dialogueBoxLabel.set_text(branch[first]["content"][0].replace("[playerSurname]", "Player"))
	speakingLabel.set_size(Vector2(0, speakingLabel.get_size().y))
	if branch[first]["content"][1]["speaking"] == "Player":
		speakingLabel.set_text("Dr " + "Player")
	else:
		speakingLabel.set_text(branch[first]["content"][1]["speaking"])
	
	if "question" in first:
		replyToOpen = true
		divert = first
	elif branch[first]["content"][1].has("isEnd"):
		toEnd = true
	else:
		divert = branch[first]["content"][1]["divert"]
	
	dialogueOpen = true

#continue from here!!!!!
func get_branch_to_play(number):
	var currentBranch = number
	var branches = ["Before Ix", "Repeated Text", "After Ix"]
	return branches[currentBranch]

func set_next():
	if toEnd == false:
		dialogueBoxLabel.set_text(branch[divert]["content"][0].replace("playerSurname", "Player"))
		set_speaking()
		if "question" in divert:
			if replyToOpen == true:
				open_reply_box()
				print_answers()
				replyToOpen = false
			else:
				replyToOpen = true
		elif "textEntry" in divert:
			if replyToOpen == true:
				replyToOpen = false
				open_reply_box()
				set_text_entry()
			else:
				replyToOpen = true
		else:
			if branch[divert]["content"][1].has("divert"):
				divert = branch[divert]["content"][1]["divert"]
			else: 
				toEnd = true
	else: 
		end_dialogue()

func set_speaking():
	if branch[divert]["content"][1]["speaking"] == "Player":
		speakingLabel.set_text("Player")
	else:
		speakingLabel.set_text(branch[divert]["content"][1]["speaking"])

var x = 0
var sizeArray = {}
func print_answers():
	replyBox.get_node("ScrollContainer").show()
	replyBox.get_node("TextEntry").hide()
	var container = replyBox.get_node("ScrollContainer/VBoxContainer")
	for btn in container.get_children():
		btn.free()
	var y = 0
	if branch[divert]["content"][1].has("adapted"):
		for bed in bed_phrases:
			add_option(bed, 1, 0)
			y += 40
	else:
		for i in range(branch[divert]["content"].size() - 2):
			var option = branch[divert]["content"][i + 2]
			add_option(option["option"], 0, i)
			y += 40
			
	replyBox.set_size(Vector2(replyBox.get_size().x, y + 56))
	set_replyBox_pos()

#print the branches. type 0 = normal, type 1 = bed phrases. 
func add_option(option, type, i):
	var container = replyBox.get_node("ScrollContainer/VBoxContainer")
	var button = Button.new()
	if type == 0:
		button.set_name(str(i + 2))
	elif type == 1:
		button.set_name(option)
	button.set_custom_minimum_size(Vector2(0, 40))
	
	var label = Label.new()
	if type == 0:
		label.set_text(option)
	elif type == 1:
		label.set_text(bed_phrases[option])
	label.set_valign(1)
	label.set_autowrap(true)
	label.set_margin(MARGIN_BOTTOM, -5)
	label.set_margin(MARGIN_TOP, 5)
	label.set_margin(MARGIN_LEFT, 10)
	label.set_margin(MARGIN_RIGHT, -10)
	label.set_anchor(MARGIN_RIGHT, 1)
	label.set_anchor(MARGIN_BOTTOM, 1)
	button.add_child(label)
	label.connect("item_rect_changed", self, "on_item_rect_changed", [label])
	
	if type == 0:
		button.connect("pressed", self, "option_selected", [button])
	elif type == 1:
		button.connect("pressed", self, "bed_phrase_selected", [button])
	container.add_child(button)
	sizeArray.clear()

func set_replyBox_pos():
	replyBox.set_position(Vector2(xAxis, ((get_viewport().get_visible_rect().size.y/2 - replyBox.get_size().y/2 - yAxis)) + 50))

#Below is a faff of a work around to resize the reply box depending on button size. Obvious coding solutions don't seem to work but this does. 
func set_reply_box(array):
	print("set_box")
	var x = 0
#	while array.size() > replyBox.get_node("ScrollContainer/VBoxContainer").get_children().size():
#		array.remove(0)
	for num in array:
		x += array[num] + 20
	if x > 160:
		replyBox.set_size(Vector2(replyBox.get_size().x, 216))
	else:
		replyBox.set_size(Vector2(replyBox.get_size().x, x + 56))



func on_item_rect_changed(label):
	label.set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	label.get_node("..").set_custom_minimum_size(Vector2(0, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count() + 20))
	sizeArray[label.get_name()] = ((label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count())
	call_deferred("set_reply_box", sizeArray)

func option_selected(chosen):
	close_reply_box()
	if branch[divert]["content"][int(chosen.get_name())].has("Answer"):
		if branch[divert]["content"][int(chosen.get_name())]["Answer"] == true:
			score += 1
	divert = branch[divert]["content"][int(chosen.get_name())]["linkPath"]
	set_next()

func bed_phrase_selected(chosen):
	close_reply_box()
	divert = branch[divert]["content"][1]["linkPath"]
	if $"..".bedContacts == null:
		bed_phrases.erase(chosen.get_name())
		$"..".bedContacts = []
	$"..".bedContacts.append(caller)
	set_next()

func text_entered(text):
	if branch[divert]["content"][1]["textToEnter"] == "First Name":
		get_node("/root/singleton").playerInfo["Forename"] = text
	elif branch[divert]["content"][1]["textToEnter"] == "Surname":
		get_node("/root/singleton").playerInfo["Surname"] = text
	close_reply_box()
	divert = branch[divert]["content"][1]["divert"]
	replyBox.get_node("TextEntry/LineEdit").clear()
	set_next()

func line_edit_text_changed(text):
	if text.length() == 0:
		replyBox.get_node("TextEntry/Button").set_disabled(true)
	else:
		if replyBox.get_node("TextEntry/Button").is_disabled():
			replyBox.get_node("TextEntry/Button").set_disabled(false)

func end_dialogue():
	get_node("../playerNode/Player").allow_movement()
	dialogueOpen = false
	if bedStory == true:
		$"..".bedStoryArray[2] += score
#		get_node("/root/World/GUI/notes").close_notes()
		if $"..".bedStoryArray[0] == 0:
			$"..".bedStoryArray[0] += 1
			print($"..".bedStoryArray[0])
	get_node("../playerNode/Player").zoom_out()
	get_node("../GUI/DialogueBox").free()

	yield(get_node("../playerNode/Player"), "zoomed_out")
	get_node("../playerNode/Player").allow_interaction()
	emit_signal("dialogue_done")

func set_text_entry():
	replyBox.get_node("ScrollContainer").hide()
	replyBox.get_node("TextEntry").show()
	replyBox.get_node("TextEntry/Button").set_disabled(true)
	replyBox.set_size(Vector2(566,72))
	replyBox.get_node("TextEntry/LineEdit").set_placeholder(branch[divert]["content"][1]["placeholder"])
	set_replyBox_pos()

func input_text():
	var text = replyBox.get_node("TextEntry/LineEdit").get_text()
	text_entered(text)

func open_reply_box():
	replyBox.show()
	canInteract = false

func close_reply_box():
	replyBox.hide()
	canInteract = true