extends NinePatchRect

onready var outputContainer = get_node("OutputContainer")
onready var labelContainer = get_node("HBoxContainer/LabelContainer")
onready var lineEditContainer = get_node("HBoxContainer/LineEditContainer")

var q_number = 4

var optionButton
func _ready():
	optionButton = get_node("OptionButton")
	for i in range(7):
		optionButton.add_item(str(i + 2))
		optionButton.select(2)
	
	for button in $QNumber/NinePatchRect.get_children():
		button.connect("pressed", self, "q_number_button_pressed", [button])

func _on_OptionButton_item_selected( ID ):
	
	var currentAnswerNo = outputContainer.get_child_count()
	var requiredAnswerNumberNo = int(optionButton.get_item_text(ID))
	var name = currentAnswerNo
	var difference = requiredAnswerNumberNo - currentAnswerNo
	print(currentAnswerNo)
	if difference > 0:
		for i in range(difference):
			var node = preload("res://Scenes/OutputIncorrect.tscn").instance()
			node.set_name("OutputIncorrect" + str(name))
			outputContainer.add_child(node)
			
			var label = preload("res://Scenes/simpleLabel.tscn").instance()
			label.set_text("Incorrect Answer:")
			labelContainer.add_child(label)
			
			#var lineEdit = preload("res://Scenes/simpleLineEdit.tscn").instance()
			var lineEdit = LineEdit.new()
			lineEditContainer.add_child(lineEdit)
			lineEdit.set_name("OutputIncorrect" + str(name))
			print(name)
			name += 1
			self.set_size(self.get_size() + Vector2(0, 26))
		for item in get_node("HBoxContainer/LineEditContainer").get_children():
			print(item.get_name())
	
	
	elif difference < 0:
		var children = outputContainer.get_children()
		var labelChildren = labelContainer.get_children()
		var lineEditChildren = lineEditContainer.get_children()
		difference = currentAnswerNo - requiredAnswerNumberNo
		for i in range(difference):
			children[currentAnswerNo - i - 1].queue_free()
			labelChildren[currentAnswerNo - i - 1].queue_free()
			lineEditChildren[currentAnswerNo - i - 1].queue_free()
			self.set_size(self.get_size() + Vector2(0, -26))
	else:
		pass
	$HBoxContainer.margin_bottom = -30
	get_node("../..").connect_node_signals(self)
	get_node("../..").update_lines(self)

func q_number_button_pressed(button):
	if button.get_name() == "AddOne" && q_number < 8:
		q_number += 1
		$QNumber.set_text(str(q_number))
		add_q_box()
	elif button.get_name() == "TakeOne" && q_number > 2:
		q_number -= 1
		$QNumber.set_text(str(q_number))
		take_q_box()

func add_q_box():
	var node = preload("res://Scenes/OutputIncorrect.tscn").instance()
	node.set_name("OutputIncorrect" + str(q_number - 1))
	outputContainer.add_child(node)

	var label = preload("res://Scenes/simpleLabel.tscn").instance()
	label.rect_min_size = Vector2(0, 26)
	label.valign = VALIGN_CENTER
	label.set_text("Incorrect Answer:")
	labelContainer.add_child(label)
	
	var lineEdit = LineEdit.new()
	lineEdit.rect_min_size = Vector2(0, 27)
	lineEditContainer.add_child(lineEdit)
	lineEdit.set_name("OutputIncorrect" + str(q_number - 1))
	
	set_size(get_size() + Vector2(0, 32))
	get_node("../..").connect_node_signals(self)
	get_node("../..").update_lines(self)

func take_q_box():
	outputContainer.get_child(outputContainer.get_child_count() - 1).queue_free()
	labelContainer.get_child(labelContainer.get_child_count() - 1).queue_free()
	lineEditContainer.get_child(lineEditContainer.get_child_count() - 1).queue_free()
	set_size(get_size() - Vector2(0, 30))

func load_q_number(diff):
	if diff > 0:
		q_number = diff + 4
		for i in range(0, diff):
			add_q_box()
	elif diff < 0:
		q_number = diff + 4
		for i in range(0, diff * -1):
			print(i)
			call_deferred("take_q_box_instafree")
	else:
		pass
	$QNumber.set_text(str(q_number))

func take_q_box_instafree():
	outputContainer.get_child(outputContainer.get_child_count() - 1).free()
	labelContainer.get_child(labelContainer.get_child_count() - 1).free()
	lineEditContainer.get_child(lineEditContainer.get_child_count() - 1).free()
	
	set_size(get_size() - Vector2(0, 30))