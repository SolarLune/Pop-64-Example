extends KinematicBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

enum State {
	ACTIVE,
	HANGING
}

var currentAnim = null
var facing = Vector3(0, 0, -1)

var moveVec = Vector3()
var tiltVec = Vector3()
var analogVec = Vector3()

var airAccelRate = 0.25
var maxSpd = 16
var friction = 2
var accelRate = 2 + friction
var gravity = 1.2
var jumpSpd = 26
var coyoteJump = null
var wasOnFloor = false
var state = State.ACTIVE
var hangingFrom = null
var letGoPosition = Vector3()

func spawnDust():		# Spawn dust function
	$DustSpawner.spawnDust()

func _ready():
	coyoteJump = get_node("CoyoteJump")

func _physics_process(delta):

	var mv = Vector3()

	var diff = get_node("../Pop").translation - translation
	diff.y = 0
	mv += diff

	mv = mv.normalized()
	
	moveVec += mv * accelRate
	
	if moveVec.length() > maxSpd:
		moveVec = moveVec.normalized() * maxSpd
	
	moveVec = move_and_slide(moveVec, Vector3(0, 1, 0), 0)
