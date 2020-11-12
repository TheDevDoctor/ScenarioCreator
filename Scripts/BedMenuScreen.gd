extends NinePatchRect

signal closed

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func close_menu():
	queue_free()
	$"../../playerNode/Player".allow_movement()
	$"../../playerNode/Player".allow_interaction()
	$"../../playerNode/Player".menuOpen = null


#func free_menu():
#
#	emit_signal("closed")
