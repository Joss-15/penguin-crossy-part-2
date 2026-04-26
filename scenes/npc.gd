extends CharacterBody3D

# Velocidad del NPC
@export var speed: float = 50.0

# Puntos A y B para el movimiento lineal
@export var point_a: Vector3 = Vector3(-1, 0, 0)
@export var point_b: Vector3 = Vector3(1, 0, 0)

var moving_to_b: bool = true
const GRAVITY = -9.8

func _ready():
	add_to_group("npc")
	global_position = point_a

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var target = point_b if moving_to_b else point_a
	var direction = (target - global_position)
	direction.y = 0

	if direction.length() < 0.2:
		moving_to_b = !moving_to_b
	else:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		rotation.y = atan2(direction.x, direction.z)

	move_and_slide()
