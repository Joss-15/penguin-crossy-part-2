extends CharacterBody3D

# ── Señales ────────────────────────────────────────────────────
signal collectible_picked
signal score_updated(new_score: int)
signal game_over_triggered(reason: String)

# ── Configuración ──────────────────────────────────────────────
const SPEED     = 5.0
const GRAVITY   = -9.8
const ROT_SPEED = 10.0

# ── Referencias ────────────────────────────────────────────────
@onready var model:    Node3D        = $penguin
@onready var camera_arm: SpringArm3D = $CameraArm
@onready var hit_area: Area3D        = $HitArea

var hud = null
var start_position: Vector3
var attempts: int = 0
var score:    int = 0

var hit_cooldown: float = 0.0
const HIT_COOLDOWN_TIME = 1.0
var _dead: bool = false  # Evitar múltiples game_over

func _ready():
	start_position = global_position
	add_to_group("player")
	hud = get_tree().get_root().find_child("HUD", true, false)
	hit_area.body_entered.connect(_on_hit_area_body_entered)

func _physics_process(delta):
	if hit_cooldown > 0:
		hit_cooldown -= delta

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_axis("ui_left",  "ui_right")
	input_dir.z = Input.get_axis("ui_up",    "ui_down")

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()
		velocity.x = input_dir.x * SPEED
		velocity.z = input_dir.z * SPEED
		var target_angle = atan2(input_dir.x, input_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle - (PI / 2.0), ROT_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

# ── Colisión con NPC ───────────────────────────────────────────
func _on_hit_area_body_entered(body: Node3D):
	if hit_cooldown > 0 or _dead:
		return
	if body.is_in_group("npc"):
		hit_by_npc()

func hit_by_npc():
	if hit_cooldown > 0 or _dead:
		return
	hit_cooldown = HIT_COOLDOWN_TIME
	attempts += 1
	if hud:
		hud.show_hit_message(attempts)
	if attempts == 3:
		_dead = true
		emit_signal("game_over_triggered", "lose") # Emitimos la señal de fin
	# Volver al inicio
	global_position = start_position
	velocity = Vector3.ZERO

# ── Recoger coleccionable ──────────────────────────────────────
func add_score():
	score += 1
	emit_signal("collectible_picked")
	emit_signal("score_updated", score)
	if hud:
		hud.update_score(score)
	ApiManager.fetch_advice()
