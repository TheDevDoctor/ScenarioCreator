extends Node

var currentPlayer = ""
var isWeb

func _ready():
	isWeb = JavaScript.eval("""
	testWeb()
	function testWeb() {
		return true
	}
	""")
	print("is web = " + str(isWeb))
	OS.set_low_processor_usage_mode(true)
#	JavaScript = ProjectSettings.get_singleton("JavaScript")
	if isWeb != null:
		get_current_player()
		get_saved_file()

func load_file_as_JSON(path):
	var file = File.new()
	file.open(path, file.READ)
	var content = (file.get_as_text())
	var target = parse_json(content)
	return target
	file.close()

func clear_container(cont):
	if cont.get_child_count() > 0:
		for child in cont.get_children():
			child.free()

func get_current_player():
	var code="""
		readCookie("username")
		function readCookie(name) {
			var nameEQ = name + "=";
			var ca = document.cookie.split(';');
			for(var i=0;i < ca.length;i++) {
				var c = ca[i];
				while (c.charAt(0)==' ') c = c.substring(1,c.length);
			if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
			}
			return "No Cookie";
		}
		"""
	var response=JavaScript.eval(code)
	currentPlayer = str(response)

func get_saved_file():
	var code="""
		var xmlHttp = new XMLHttpRequest();
		xmlHttp.open("PUT", "https://pixeldr.azurewebsites.net/gameapis/cosmosdbapi/load-savedscenario/""" + currentPlayer + """", false);
		xmlHttp.setRequestHeader("Content-Type", "application/json");
		xmlHttp.send();
		xmlHttp.response;"""
	var response=JavaScript.eval(code)
	print(response)
	var dict = {}
	dict = parse_json(response)
	var dict2 = {}
	dict2 = parse_json(dict["result"])
	var savejson = File.new()
	savejson.open("user://saved_scenarios.json", File.WRITE)
	savejson.store_line(to_json(dict2))
	savejson.close()

func send_save_file(save_file):
	save_file.erase("_etag")
	var json = to_json(save_file)
	json = json.replace("'","")
	json = json.replace("\\n","")
	var code="""
		var xmlHttp = new XMLHttpRequest();
		xmlHttp.open("PUT", "https://pixeldr.azurewebsites.net/gameapis/cosmosdbapi/update-savedscenario/""" + currentPlayer + """", true);
		xmlHttp.setRequestHeader("Content-Type", "application/json");
		xmlHttp.send(`%s`);
		xmlHttp.response;""" % (json)
	print(code)
	var response = JavaScript.eval(code)
	print(response)

func hide_label(ID, node):
	if node.get_node("Label").is_visible():
		node.get_node("Label").hide()
