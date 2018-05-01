extends Spatial

var myMat = null

func _ready():
	
	myMat = preload("Dust.material").duplicate()
	
	for node in get_children():
		var mat = node.set_surface_material(0, myMat)
	
	set_process(true)

func _process(delta):
	scale = scale.normalized() * (scale.length() + .05)
	myMat.albedo_color.a -= 0.05
	if myMat.albedo_color.a <= 0:
		queue_free()
