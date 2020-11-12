extends Node

signal timer_done
signal question_sent

#var tcp = StreamPeerTCP.new()
#var peer = PacketPeerStream.new()
#var _conn = false
var asked = {}
var dict = {"Test": "this si the text"}
var currentQ
var inGame = false
var botCurrentQ

onready var scrollContainer = get_node("Container/ScrollContainer")
onready var VBox = get_node("Container/ScrollContainer/VBox")
var x = 0
var y = 0
var diction = {}
var timer = 0.0

var thread = Thread.new()
var canSend = true
#var JavaScript

func _ready():
	get_node("Container/LineEdit").connect("text_changed", self, "question_text_changed")
	set_process_unhandled_key_input(true)
	set_process(false)
#	JavaScript = ProjectSettings.get_singleton("JavaScript")
#	make_connection()
#	if singleton.bedHistory[singleton.currentWard][get_node("/root/World/playerNode/Player").target.get_name()] != null:
#		asked = singleton.bedHistory[singleton.currentWard][get_node("/root/World/playerNode/Player").target.get_name()] 

func _unhandled_key_input(key_event):
	if key_event.is_action_pressed("ui_enter") && canSend == true:
		print("enter_question")
		enter_question()
	if key_event.is_action_pressed("ui_cancel") && canSend == true && inGame:
		close_history_bot()

func _process(delta):
	if timer > 0:
		timer -= delta
		emit_signal("timer_done")

#func set_bed_data(bed):
#	pass

func question_text_changed(text):
	if text.length() > 0:
		add_typing_box("player")
	else:
		remove_typing_box("playerTyping")

func set_bed_data():
	diction = get_node("/root/MainFrame").scenarioDict["History"]

func enter_question():
	var text = get_node("Container/LineEdit").get_text()
	if text.length() > 0:
		add_text_to_container(text, "player")
		add_typing_box("patient")
		send_question(text)
		clear_line_edit()

func add_typing_box(typing):
	if VBox.has_node(typing + "Typing") == false:
		var node = preload("res://Scenes/chatBoxBot.tscn").instance()

		node.set_name(typing + "Typing")
		node.set_name(typing + "Typing")
		if typing == "patient":
			node.set_texture(load("res://Graphics/patientChatBox.png"))
			node.set_patch_margin(MARGIN_RIGHT, 34)
			node.set_patch_margin(MARGIN_LEFT, 18)
			node.get_node("TextureFrame").set_margin(MARGIN_LEFT, 21)
			node.get_node("TextureFrame").set_margin(MARGIN_RIGHT, 38)
			node.get_node("TextureFrame").set_self_modulate(Color(0.608963,0.980469,0.490234))
		VBox.add_child(node)
		if typing == "patient":
			if inGame:
				x = VBox.get_size().x - node.get_size().x
			else:
				x = VBox.get_size().x - node.get_size().x - 250
		else:
			if inGame:
				x = 0
			else:
				x = 95
		print(x)
		node.set_position(Vector2(x,y))
		var height = node.get_size().y
		change_box_sizes(height, 0)

func remove_typing_box(typing):
	if VBox.has_node(typing):
		var hieght = VBox.get_node(typing).get_size().y
		change_box_sizes(hieght, 1)
		VBox.get_node(typing).free()

var i = 0
func add_text_to_container(text, from):
	var box = VBox.get_node(from + "Typing")
	box.get_node("TextureFrame").free()
	var label = Label.new()
	label.set_margin(MARGIN_TOP, 10)
	label.set_margin(MARGIN_BOTTOM, 30)
	if from == "player":
		label.set_margin(MARGIN_LEFT, 36)
		label.set_margin(MARGIN_RIGHT, 10)
	else:
		label.set_margin(MARGIN_LEFT, 15)
		label.set_margin(MARGIN_RIGHT, 36)
	label.set_text(text)
	box.add_child(label)
	i += 1
	box.set_name(text)
	check_label_size(label, from)

func check_label_size(label, from):
	if label.get_size().x > 330:
		label.set_autowrap(true)
		label.set_size(Vector2(330, label.get_size().y))
		change_label_height(label)
	else:
		label.get_node("..").set_custom_minimum_size(Vector2(label.get_size().x + 52, label.get_size().y))
	
	if from == "patient":
		if inGame:
			label.get_node("..").set_position(Vector2(VBox.get_size().x - label.get_node("..").get_custom_minimum_size().x, label.get_node("..").get_position().y))
		else:
			label.get_node("..").set_position(Vector2(VBox.get_size().x - label.get_node("..").get_custom_minimum_size().x - 100, label.get_node("..").get_position().y))
	
	if inGame == false:
		add_side_button(from, label.get_node(".."))

func add_side_button(from, speechBubble):
	if from == "player":
		var node = preload("res://Scenes/QCorrectButton.tscn").instance()
		node.set_position(Vector2(83, speechBubble.get_position().y + speechBubble.get_size().y + 5))
		node.set_name(speechBubble.get_name() + "xxqxxq")
		node.connect("pressed", self, "correct_on_testing_pressed", [node])
		print(node.get_name())
		VBox.add_child(node)
	else:
		var node = preload("res://Scenes/EditResponseButton.tscn").instance()
		node.set_position(Vector2(535, speechBubble.get_position().y + speechBubble.get_size().y - 17))
		VBox.add_child(node)
		node.set_name(botCurrentQ + "bxxbxx")
		node.connect("pressed", self, "edit_on_testing_pressed", [node])
		print(node.get_name())

func correct_on_testing_pressed(node):
	var text = node.get_name()
	text = text.replace("xxqxxq", "")
	$"../../..".add_correct_pressed(text)

func edit_on_testing_pressed(node):
	var text = node.get_name()
	text = text.replace("bxxbxx", "")
	print(text)
	$"../../..".edit_question_pressed(text)

func change_label_height(label):
	label.set_size(Vector2(330, (label.get_line_height()+label.get_constant("line_spacing")) * label.get_line_count()))
	var size = label.get_size()
	label.get_node("..").set_custom_minimum_size(Vector2(size.x + 52, size.y + 30))
	var difference = label.get_node("..").get_custom_minimum_size().y - 46
	change_box_sizes(difference, 0)
	if VBox.has_node("playerTyping"):
		VBox.get_node("playerTyping").set_position(VBox.get_node("playerTyping").get_position() + Vector2(0, difference))

func send_question(text):
	canSend = false

	currentQ = text
	var send = text.replace("'", "")
	var inputDict = {"question": send}
	if singleton.isWeb != null:
		print("java")
		var code="""
			var xmlHttp = new XMLHttpRequest();
			xmlHttp.open( "POST", "https://westus.api.cognitive.microsoft.com/qnamaker/v2.0/knowledgebases/****************************/generateAnswer", false );
			xmlHttp.setRequestHeader("Ocp-Apim-Subscription-Key", "**************************");
			xmlHttp.setRequestHeader("Content-Type", "application/json");
			xmlHttp.send( '%s' );
			xmlHttp.responseText;""" % (JSON.print(inputDict))
		var response=JavaScript.eval(code)
		print(code)
		print(response)
		return_string_from_bot(response)
	else:
		if inGame:
			get_node("/root/HTTPClientScript").talkToServer("/qnamaker/v2.0/knowledgebases/****************************/generateAnswer", "game", inputDict)
		else:
			get_node("/root/HTTPClientScript").talkToServer("/qnamaker/v2.0/knowledgebases/****************************/generateAnswer", "bot", inputDict)
	canSend = true
	emit_signal("question_sent")
#	thread.wait_to_finish()
	

func change_box_sizes(height, type):
	var scrollHeight
	if height > (scrollContainer.get_margin(MARGIN_TOP) - 9):
		scrollHeight = scrollContainer.get_margin(MARGIN_TOP) - 9
	else:
		scrollHeight = height
		
	if type == 0:
		if scrollContainer.get_margin(MARGIN_TOP) > 9:
			scrollContainer.set_size(Vector2(scrollContainer.get_size().x, scrollContainer.get_size().y + scrollHeight))
			scrollContainer.set_position(Vector2(scrollContainer.get_position().x, scrollContainer.get_position().y - scrollHeight))
		VBox.set_custom_minimum_size(Vector2(VBox.get_custom_minimum_size().x, VBox.get_custom_minimum_size().y + height))
		y += height
	elif type == 1:
		if scrollContainer.get_margin(MARGIN_TOP) > 9:
			scrollContainer.set_size(Vector2(scrollContainer.get_size().x, scrollContainer.get_size().y - scrollHeight))
			scrollContainer.set_position(Vector2(scrollContainer.get_position().x, scrollContainer.get_position().y + scrollHeight))
		VBox.set_custom_minimum_size(Vector2(VBox.get_custom_minimum_size().x, VBox.get_custom_minimum_size().y - height))
		y -= height
	
	set_process(true)
	timer = 0.2
	yield(self, "timer_done")
	scrollContainer.set_v_scroll(10000)
	set_process(false)


func return_string_from_bot(RESULT):
	var dict = {}
	dict = parse_json(RESULT)
	var text
	var textSet = false
	if dict["answers"][0]["questions"].size() > 0:
		botCurrentQ = dict["answers"][0]["questions"][0]
		asked[botCurrentQ] = currentQ
		for question in dict["answers"][0]["questions"]:
			if textSet == false:
				if diction.has(question):
					text = diction[question]
					textSet = true
				else:
					text = dict["answers"][0]["answer"].replace("&#39;", "'")
	else:
		text = "I'm sorry doctor I didn't understand the question."
	add_text_to_container(text, "patient")
	print(text)
	print(asked)

func clear_line_edit():
	get_node("Container/LineEdit").clear()
#
#func make_connection(endPoint, port):
#	if tcp.get_status() != 0:
#		disconnect()
#	print("Started!")
#	tcp.connect_to_host(endPoint, port)
#	print("Connecting...")
#	set_process(true)
#
#func disconnect():
#	tcp.disconnect_from_host()

func close_history_bot():
	get_node("../../playerNode/Player").zoom_out()

	if $"../..".bedHistory == null:
		$"../..".bedHistory = {}
		$"../..".bedHistory = asked
	else:
		$"../..".bedHistory = asked
	get_node("../../GUI/notes").close_notes()

#	self.hide()
	yield($"../../playerNode/Player", "zoomed_out")
	get_node("../../playerNode/Player").allow_movement()
	get_node("../../playerNode/Player").allow_interaction()
	queue_free()
	get_node("../../playerNode/Player").menuOpen = null
	$"/root/MainFrame/Current/TestScreen".history = false
	print("freed")

