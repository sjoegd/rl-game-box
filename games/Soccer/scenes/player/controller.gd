extends AIController2D

func get_obs() -> Dictionary:
	assert(false, "the get_obs method is not implemented when extending from ai_controller") 
	return {"obs":[]}

func get_reward() -> float:	
	assert(false, "the get_reward method is not implemented when extending from ai_controller") 
	return 0.0
	
func get_action_space() -> Dictionary:
	assert(false, "the get get_action_space method is not implemented when extending from ai_controller") 
	return {
		"example_actions_continous" : {
			"size": 2,
			"action_type": "continuous"
		},
		"example_actions_discrete" : {
			"size": 2,
			"action_type": "discrete"
		},
		}
	
func set_action(action) -> void:	
	assert(false, "the get set_action method is not implemented when extending from ai_controller")
