extends Area3D

# ── Señales ────────────────────────────────────────────────────
signal collectible_picked(position: Vector3)

const ROT_SPEED   = 2.0
const FLOAT_AMP   = 0.15
const FLOAT_SPEED = 2.0

var _base_y:    float
var _time:      float = 0.0
var _collected: bool  = false

@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var mesh:  MeshInstance3D      = $MeshInstance3D
@onready var shape: CollisionShape3D    = $CollisionShape3D

func _ready():
	_base_y = position.y
	add_to_group("collectible")
	body_entered.connect(_on_body_entered)
	# Cuando termine el audio, liberar el nodo
	audio.finished.connect(queue_free)

func _process(delta):
	if _collected:
		return
	_time += delta
	rotation.y += ROT_SPEED * delta
	position.y = _base_y + sin(_time * FLOAT_SPEED) * FLOAT_AMP

func _on_body_entered(body: Node3D):
	if _collected:
		return
	if body.is_in_group("player"):
		_collected = true
		# Ocultar mesh y desactivar colisión inmediatamente
		mesh.visible       = false
		shape.disabled     = true
		# Sumar puntos al jugador
		body.add_score()
		emit_signal("collectible_picked", global_position)
		# Reproducir sonido — queue_free() se llama al terminar
		audio.play()
