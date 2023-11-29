extends CharacterBody3D


const SPEED = 25
const JUMP_VELOCITY = 10

@export var mass = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	var collisions = move_and_collide(velocity*delta)
	if collisions:
		handle_collisions(collisions)

func handle_collisions(collisions: KinematicCollision3D):
	for i in range(collisions.get_collision_count()):
		var collider = collisions.get_collider(i)
		if collider is RigidBody3D:
			var vel_diff = (collider.linear_velocity - velocity).length()
			var force = -collisions.get_normal(i)*mass*vel_diff
			collider.apply_force(force, collisions.get_position(i))

func is_grounded() -> bool:
	return test_move(transform, Vector3.DOWN*0.05)
