extends Container

var correctExams = []


func _ready():
	$Container/Correct.connect("pressed", self, "correct_pressed")
	
	var data = get_node("../..").scenarioDict
	if data.has("Examinations"):
		$Container/NinePatchRect/Patch9Frame.examChange = data["Examinations"]
		correctExams = data["Answers"]["Examinations"]
		load_examination_data()

func correct_pressed():
	var exam = $Container/NinePatchRect/Patch9Frame.examSelected
	add_correct(exam)

func add_correct(exam):
	if $PatientDetails2/ScrollContainer/VBoxContainer.has_node(exam) == false:
		var node = preload("res://Scenes/CorrectQ.tscn").instance()
		node.get_node("Question").set_text(exam)
		node.get_node("Close").connect('pressed', self, 'remove_correct_exam', [node])
		node.set_name(exam)
		$PatientDetails2/ScrollContainer/VBoxContainer.add_child(node)
		if correctExams.has(exam) == false:
			correctExams.append(exam)

func remove_correct_exam(node):
	correctExams.erase(node.get_name())
	node.free()

func save_correct_examinations():
	pass

func load_examination_data():
	for exam in correctExams:
		add_correct(exam)
	$Container/NinePatchRect/Patch9Frame.load_examinations_changed()
	