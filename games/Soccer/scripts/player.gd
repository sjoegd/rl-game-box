extends CharacterBody3D
class_name Player

@export var mass := 2.0
@export var speed := 15.0
@export var jump_speed := 7.5
@export var rotate_speed := PI
@export var fast_rotate_multiplier := 1.5
@export var dash_speed := 30.0
@export var dash_period := 0.15 #s
@export var dash_cooldown := 1 #s
@export var color := "lightblue"

@onready var rigid_collider = $RigidCollider
@onready var camera_holder = $CameraHolder
@onready var mesh := $RigidCollider/Mesh
@onready var base_transform = transform

var gravity := 9.8 * mass

var can_dash := true
var is_dashing := false

func _ready():
	_update_rigid_collider()
	_update_color(Color(color))

func _update_color(_color: Color):
	var material = mesh.get_active_material(0).duplicate()
	material.albedo_color = _color
	mesh.set_surface_override_material(0, material)

func reset():
	transform = base_transform
	velocity = Vector3.ZERO
	camera_holder.reset()

func _physics_process(delta):
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if not is_dashing:
		var input_rotate = Input.get_axis("rotate_right", "rotate_left")
		if Input.is_action_pressed("fast_rotate"):
			input_rotate *= fast_rotate_multiplier
		rotate_y(input_rotate*rotate_speed*delta)
		
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (
			transform.basis * Vector3(input_dir.x/2, 0, input_dir.y)
		).normalized()*speed
		
		velocity.x = direction.x
		velocity.z = direction.z
		
		if can_dash and Input.is_action_just_pressed("dash"):
			_start_dash()
			var direction_basis = transform.basis * Vector3.FORWARD
			if direction:
				direction_basis = direction/speed
			velocity.x = direction_basis.x * dash_speed
			velocity.z = direction_basis.z * dash_speed
	
	move_and_slide()
	_update_rigid_collider()
	_update_camera_holder(delta)

func _start_dash():
	can_dash = false
	is_dashing = true
	get_tree().create_timer(dash_period, true, true).timeout.connect(_on_dash_end)

func _on_dash_end():
	is_dashing = false
	get_tree().create_timer(dash_cooldown, true, true).timeout.connect(_on_dash_recharge)

func _on_dash_recharge():
	can_dash = true

func _update_rigid_collider():
	rigid_collider.global_transform = global_transform
	rigid_collider.linear_velocity = velocity
	rigid_collider.angular_velocity = Vector3.ZERO

func _update_camera_holder(delta):
	camera_holder.global_position = lerp(camera_holder.global_position, global_position, delta*20)
	var current_camera_rotation = camera_holder.transform.basis.get_rotation_quaternion()
	var target_camera_rotation = transform.basis.get_rotation_quaternion()
	var smooth_rotation = current_camera_rotation.slerp(target_camera_rotation, delta*10)
	camera_holder.global_rotation = smooth_rotation.get_euler()
