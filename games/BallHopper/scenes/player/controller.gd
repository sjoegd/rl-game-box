extends AIController2D

var move_side: float = 0.0

@onready var ball_sensor: RaycastSensor2D = $BallSensor as RaycastSensor2D
@onready var static_sensor: RaycastSensor2D = $StaticSensor as RaycastSensor2D

func get_obs() -> Dictionary:
	return {"obs": 
		ball_sensor.get_observation() +
		static_sensor.get_observation()
	}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
			"move_side" : {
				"size": 1,
				"action_type": "continuous"
			},
		}
	
func set_action(action) -> void:	
	move_side = action["move_side"][0]
