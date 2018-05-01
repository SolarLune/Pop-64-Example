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

	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().get_root().queue_free()
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

	var mv = Vector3()
	var tiltMagnitude = 0
	
	var targetAnim = null
	
	if Input.is_action_pressed("ui_right"):
		mv.x -= 1
	if Input.is_action_pressed("ui_left"):
		mv.x += 1
		
	if Input.is_action_pressed("ui_down"):
		mv.z -= 1
	if Input.is_action_pressed("ui_up"):
		mv.z += 1
	
	tiltMagnitude = mv.length()
		
	if Input.get_joy_name(0) != null and mv.length() == 0:
		
		mv.x = -Input.get_joy_axis(0, 0)
		mv.z = -Input.get_joy_axis(0, 1)
		tiltMagnitude = mv.length()
		
		if tiltMagnitude <= 0.1:
			mv.x = 0
			mv.z = 0
	
	mv = mv.normalized()
	
	var b = Basis(get_viewport().get_camera().global_transform.basis)
	b.z.y = 0 # Crush Y so movement doesn't go into ground
	b.z = b.z.normalized()
	mv = b.xform(mv)
	
	mv.z *= -1
	mv.x *= -1
	
	if mv.length() > 0:
		analogVec = mv
	
	if state == ACTIVE:
				
		if is_on_floor():
			if mv.length() > 0:
					targetAnim = "PopRun-loop"
			else:
				targetAnim = "PopIdle-loop"
		else:
			targetAnim = "PopJump-loop"
		
		facing += (analogVec.normalized() - facing) * .25
		facing = facing.normalized()
		facing.y = 0
		get_node("PopArmHandle").look_at(translation - facing, Vector3(0, 1, 0) + (tiltVec * .25))
		
		if is_on_floor():
			var mt = Vector3(moveVec.x, moveVec.y, moveVec.z)
			mt.y = 0
			if mt.length() > friction:
				var frict = moveVec.normalized() * friction
				frict.y = 0
				moveVec -= frict
			else:
				moveVec.x = 0
				moveVec.z = 0
				
			if mv.length() > 0:
				moveVec += mv * accelRate
		elif mv.length() > 0:
			moveVec += mv * airAccelRate
		
		var yspd = moveVec.y
		
		moveVec.y = 0
		
		var mSpd = maxSpd
		
		if is_on_floor():
			mSpd *= tiltMagnitude
		
		if moveVec.length() > mSpd:
			moveVec = moveVec.normalized() * mSpd
		
		moveVec.y = yspd - gravity
		
		if is_on_floor():
			coyoteJump.start()
			letGoPosition = translation
			if not wasOnFloor:
				spawnDust()
				
		var down = $PopArmHandle/LedgeDown
		var forward = $PopArmHandle/LedgeForward
		if down.is_colliding() and forward.is_colliding() and moveVec.y < 0 and not is_on_floor():
			var fallDiff = translation - letGoPosition
			if forward.get_collider() == down.get_collider():
				if forward.get_collision_normal().y <= 0 and down.get_collision_normal().y > 0.5 and fallDiff.length() > 1:
					hangingFrom = forward.get_collider()
					state = HANGING
					translation = forward.get_collision_point() + forward.get_collision_normal() * .5			
					translation.y = down.get_collision_point().y - 2
					$PopArmHandle.look_at(translation + forward.get_collision_normal(), Vector3(0, 1, 0))
			
	elif state == HANGING:
		
		if Input.is_action_just_pressed("interact"):	# Let go
			state = ACTIVE
			letGoPosition = translation
		
		targetAnim = "PopHang-loop"
		
		moveVec.x = 0
		moveVec.y = 0
		moveVec.z = 0
		
		if $PopArmHandle/LedgeDown.is_colliding() and $PopArmHandle/LedgeDown.get_collision_normal().y >= 0.99:
		
			var right = $PopArmHandle/LedgeForward.get_collision_normal().cross(Vector3(0, 1, 0))
			
			var vec = Vector3()
			
			if mv.dot(right) > 0.25:
				vec += right
			elif mv.dot(right) < -0.25:
				vec -= right
			
			moveVec += vec * 5
		
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyoteJump.get_time_left() > 0 or state == HANGING):
		moveVec.y = jumpSpd
		coyoteJump.stop()
		state = ACTIVE	
	
	wasOnFloor = is_on_floor()
		
	var prevPos = translation
	
	moveVec = move_and_slide(moveVec, Vector3(0, 1, 0), 0)
	
	if state == HANGING:
		$PopArmHandle/LedgeForward.force_raycast_update()
		$PopArmHandle/LedgeDown.force_raycast_update()
		if not $PopArmHandle/LedgeForward.is_colliding() or $PopArmHandle/LedgeForward.get_collider() != hangingFrom:
			## TO-DO: Use areas to determine if edge drops off
			# We slid off the ledge
			translation = prevPos
	
	var player = $AnimationPlayer
	if not player.is_playing() or currentAnim != targetAnim:
		if targetAnim == "PopRun-loop":
			$DustAnimation.play("PopRunDust")
		else:
			$DustAnimation.stop()
		player.play(targetAnim, 0.1)
		currentAnim = targetAnim
	
	var t = moveVec.normalized()
	if moveVec.length() > 0.01:
		tiltVec += (moveVec.normalized() - tiltVec) * .1
	else:
		tiltVec.x -= tiltVec.x * .1
		tiltVec.y -= tiltVec.y * .1
		tiltVec.z -= tiltVec.z * .1
	
	if translation.y < -100:
		get_tree().reload_current_scene()
	