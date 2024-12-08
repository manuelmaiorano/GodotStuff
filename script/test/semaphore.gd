extends Node
class_name IntersectionSemaphore

enum SEMAPHORE_STATE {YELLOW, GREEN, RED}
signal turned(state: SEMAPHORE_STATE)

var state: SEMAPHORE_STATE
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
