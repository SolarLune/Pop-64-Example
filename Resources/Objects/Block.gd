extends StaticBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	var mesh = find_node("MeshInstance")
	var newMat = mesh.get_surface_material(0).duplicate()
	newMat.set_albedo(Color(randf(), randf(), randf(), 1))	
	mesh.set_surface_material(0, newMat)
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
