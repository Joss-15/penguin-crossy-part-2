extends Node

# ── Autoload: ApiManager ───────────────────────────────────────
# Consulta la Advice Slip API y emite señales con el resultado.
# Registrado en Project Settings > Autoload como "ApiManager".
# API usada: https://api.adviceslip.com/advice
# Efecto en gameplay: al recoger una estrella se muestra un consejo.
# Cada 3 estrellas recogidas se duplica la velocidad de los NPCs 5 seg.

signal advice_received(text: String)
signal speed_boost_triggered()

var _http: HTTPRequest
var _collect_count_ref: int = 0   # referencia al score actual

func _ready():
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

# Llamado desde Level.gd cada vez que se recoge una estrella
func fetch_advice():
	# cache buster para evitar respuesta cacheada
	var url = "https://api.adviceslip.com/advice?t=" + str(Time.get_ticks_msec())
	_http.request(url)

func _on_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		emit_signal("advice_received", "¡Sigue adelante, Pingu!")
		return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json and json.has("slip"):
		var advice: String = json["slip"]["advice"]
		emit_signal("advice_received", advice)
		# Si el ID del consejo es par → emitir boost de velocidad
		var slip_id: int = json["slip"]["id"]
		if slip_id % 2 == 0:
			emit_signal("speed_boost_triggered")
	else:
		emit_signal("advice_received", "¡Sigue adelante, Pingu!")
