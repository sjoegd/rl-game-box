extends CharacterBody2D

"""
Huge thanks to:
	https://engineeringdotnet.blogspot.com/2010/04/simple-2d-car-physics-in-games.html
"""

@export var color: String = "blue"

@onready var front_wheel_right = $Sprites/Wheels/FrontRight
@onready var front_wheel_left = $Sprites/Wheels/FrontLeft
@onready var front_wheel_position = $Markers/FrontWheel
@onready var back_wheel_position = $Markers/BackWheel

var car_location: Vector2
var car_heading: float
var car_speed: float = 600
var steer_angle: float = PI/4
@onready var wheel_base: float = front_wheel_position.global_position.distance_to(back_wheel_position.global_position)

func _ready():
	set_color(color)

func set_color(c: String):
	$Sprites/Frames.get_node(c.capitalize()).visible = true

func _physics_process(delta):
	var input = get_input()
	move_car(delta, input[0], input[1])

func get_input():
	var input_steer = 0
	var input_acceleration = 0
	
	if Input.is_action_pressed("forward"):
		input_acceleration += 1
	if Input.is_action_pressed("backward"):
		input_acceleration -= 1
	
	if Input.is_action_pressed("right"):
		input_steer += 1
	if Input.is_action_pressed("left"):
		input_steer -= 1
	
	return [input_acceleration, input_steer]

func move_car(delta, input_acceleration: float, input_steer: float):
	var steer: float = input_steer * steer_angle
	var accelaration: float = input_acceleration * car_speed
	
	var front_wheel_vector: Vector2 = (
		position + (wheel_base/2 * Vector2(cos(car_heading), sin(car_heading)))
	)
	var back_wheel_vector: Vector2 = (
		position - (wheel_base/2 * Vector2(cos(car_heading), sin(car_heading)))
	)
	
	front_wheel_vector += accelaration * delta * Vector2(cos(car_heading+steer), sin(car_heading+steer))
	back_wheel_vector += accelaration * delta * Vector2(cos(car_heading), sin(car_heading))
	
	car_location = (front_wheel_vector + back_wheel_vector) / 2
	car_heading = atan2(front_wheel_vector.y - back_wheel_vector.y, front_wheel_vector.x - back_wheel_vector.x)
	
	var motion = car_location - position
	move_and_collide(motion)
	
	rotation = car_heading
	front_wheel_left.rotation = steer
	front_wheel_right.rotation = steer

