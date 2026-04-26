extends CanvasLayer

# ── Referencias ────────────────────────────────────────────────
@onready var message_label:   Label  = $MessageLabel
@onready var attempts_label:  Label  = $AttemptsLabel
@onready var score_label:     Label  = $ScoreLabel
@onready var highscore_label: Label  = $HighScoreLabel
@onready var advice_label:    Label  = $AdviceLabel
@onready var game_over_panel: Panel  = $GameOverPanel
@onready var go_title:        Label  = $GameOverPanel/Title
@onready var go_score:        Label  = $GameOverPanel/ScoreLabel
@onready var go_record:       Label  = $GameOverPanel/RecordLabel
@onready var go_new_record:   Label  = $GameOverPanel/NewRecordLabel
@onready var go_button:       Button = $GameOverPanel/RestartButton

var message_timer: float = 0.0
var advice_timer:  float = 0.0
const MESSAGE_DURATION = 3.0
const ADVICE_DURATION  = 5.0

func _ready():
	add_to_group("hud")
	message_label.visible   = false
	advice_label.visible    = false
	game_over_panel.visible = false
	attempts_label.text     = "Intentos: 0"
	score_label.text        = "⭐ Estrellas: 0"
	var hs = Database.get_high_score()
	highscore_label.text    = "🏆 Récord: " + str(hs)
	ApiManager.advice_received.connect(_on_advice_received)
	ApiManager.speed_boost_triggered.connect(_on_speed_boost)
	go_button.pressed.connect(_on_restart_pressed)

func _process(delta):
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message_label.visible = false
	if advice_timer > 0:
		advice_timer -= delta
		if advice_timer <= 0:
			advice_label.visible = false

# ── Score ──────────────────────────────────────────────────────
func update_score(new_score: int):
	score_label.text = "⭐ Estrellas: " + str(new_score)
	var hs = Database.get_high_score()
	highscore_label.text = "🏆 Récord: " + str(hs)

# ── Mensaje de golpe ───────────────────────────────────────────
func show_hit_message(attempts: int):
	message_label.text    = "¡Golpeaste un NPC! Vuelves al inicio"
	message_label.visible = true
	message_timer         = MESSAGE_DURATION
	attempts_label.text   = "Intentos: " + str(attempts)

# ── API ────────────────────────────────────────────────────────
func _on_advice_received(text: String):
	advice_label.text    = "💡 " + text
	advice_label.visible = true
	advice_timer         = ADVICE_DURATION

func _on_speed_boost():
	advice_label.text    = "⚡ ¡Evento! Los NPCs aceleran 5 segundos..."
	advice_label.visible = true
	advice_timer         = ADVICE_DURATION

# ── Pantalla de Game Over ──────────────────────────────────────
func show_game_over(reason: String, score: int, high_score: int, is_new_record: bool):
	game_over_panel.visible = true
	# Título según la razón
	if reason == "win":
		go_title.text = "🎉 ¡Recogiste todo!"
		go_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	else:
		go_title.text = "💀 ¡Fin de la partida!"
		go_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	go_score.text      = "Estrellas: " + str(score)
	go_record.text     = "🏆 Récord: " + str(high_score)
	go_new_record.visible = is_new_record
	highscore_label.text  = "🏆 Récord: " + str(high_score)

# ── Reiniciar ─────────────────────────────────────────────────
func _on_restart_pressed():
	get_tree().reload_current_scene()
