extends Node3D

# ── Configuración ──────────────────────────────────────────────
const BOOST_DURATION   = 5.0
const BOOST_MULTIPLIER = 2.5

# Rango de spawn de monedas (dentro del área de los NPCs)
const SPAWN_X_MIN = -7.0
const SPAWN_X_MAX =  7.0
const SPAWN_Z_MIN = -13.0   # Carril más lejano
const SPAWN_Z_MAX = -3.0    # Carril más cercano
const SPAWN_Y     =  0.5
const SPAWN_INTERVAL = 1.0  # Segundos entre cada moneda

var _npc_base_speeds: Dictionary = {}
var _boost_timer:     float = 0.0
var _boosted:         bool  = false
var _game_over:       bool  = false

var _spawn_timer:     float = 0.0
var _collectible_scene = preload("res://scenes/Collectible.tscn")

func _ready():
	# Guardar velocidades base de todos los NPCs
	for npc in get_tree().get_nodes_in_group("npc"):
		_npc_base_speeds[npc] = npc.speed

	# Conectar señales
	ApiManager.speed_boost_triggered.connect(_on_speed_boost)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.collectible_picked.connect(_on_collectible_picked)
		player.game_over_triggered.connect(_on_game_over)

func _process(delta):
	if _game_over:
		return

	# ── Spawn de monedas cada segundo ─────────────────────────
	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_collectible()

	# ── Speed boost de API ────────────────────────────────────
	if _boosted:
		_boost_timer -= delta
		if _boost_timer <= 0:
			_remove_boost()

# ── Generar moneda en posición aleatoria ───────────────────────
func _spawn_collectible():
	var col = _collectible_scene.instantiate()
	var rand_x = randf_range(SPAWN_X_MIN, SPAWN_X_MAX)
	var rand_z = randf_range(SPAWN_Z_MIN, SPAWN_Z_MAX)
	col.position = Vector3(rand_x, SPAWN_Y, rand_z)
	add_child(col)
	# Conectar señal del nuevo coleccionable al jugador
	var player = get_tree().get_first_node_in_group("player")
	if player and col.has_signal("collectible_picked"):
		col.collectible_picked.connect(func(_pos): player.collectible_picked.emit())

# ── Una estrella recogida ──────────────────────────────────────
func _on_collectible_picked():
	pass  # Juego infinito — no hay condición de victoria por monedas

# ── Fin de partida ─────────────────────────────────────────────
func _on_game_over(reason: String):
	if _game_over:
		return
	_game_over = true

	for npc in get_tree().get_nodes_in_group("npc"):
		if is_instance_valid(npc):
			npc.set_physics_process(false)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		player.velocity = Vector3.ZERO
		var is_new_record = Database.try_save_score(player.score)
		var high_score    = Database.get_high_score()
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_game_over(reason, player.score, high_score, is_new_record)

# ── Speed boost de API ─────────────────────────────────────────
func _on_speed_boost():
	if _boosted:
		return
	_boosted     = true
	_boost_timer = BOOST_DURATION
	for npc in _npc_base_speeds.keys():
		if is_instance_valid(npc):
			npc.speed = _npc_base_speeds[npc] * BOOST_MULTIPLIER

func _remove_boost():
	_boosted = false
	for npc in _npc_base_speeds.keys():
		if is_instance_valid(npc):
			npc.speed = _npc_base_speeds[npc]
