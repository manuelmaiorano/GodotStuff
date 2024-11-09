extends PathFollow3D

@export var velocitykmh := 40.0

var elapsed = 0.0

func _process(delta: float) -> void:
	elapsed += delta
	progress = velocitykmh * 0.28 * elapsed
