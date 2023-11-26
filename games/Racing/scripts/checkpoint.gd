extends Node3D
class_name CheckPoint

signal car_detected(car: Car)

func _on_car_detected(body):
	if not body is Car:
		return
	car_detected.emit(body as Car)
