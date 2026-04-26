extends Node

# ── Autoload: Database ─────────────────────────────────────────
# Gestiona la base de datos SQLite con la tabla highscores.
# Registrado en Project Settings > Autoload como "Database".

var db: SQLite

func _ready():
	db = SQLite.new()
	db.path = "user://game_data.db"
	db.verbosity_level = SQLite.QUIET
	db.open_db()
	_create_table()

func _create_table():
	db.query("""
		CREATE TABLE IF NOT EXISTS highscores (
			id          INTEGER PRIMARY KEY AUTOINCREMENT,
			player_name TEXT    DEFAULT 'Jugador',
			max_score   INTEGER DEFAULT 0,
			date        TEXT
		)
	""")
	# Insertar fila inicial si la tabla está vacía
	db.query("SELECT COUNT(*) as count FROM highscores")
	var count = db.query_result[0]["count"]
	if count == 0:
		db.query("INSERT INTO highscores (player_name, max_score, date) VALUES ('Jugador', 0, date('now'))")

# Obtener la puntuación máxima guardada
func get_high_score() -> int:
	db.query("SELECT max_score FROM highscores ORDER BY max_score DESC LIMIT 1")
	if db.query_result.size() > 0:
		return db.query_result[0]["max_score"]
	return 0

# Guardar si la puntuación actual supera el récord
func try_save_score(score: int) -> bool:
	var best = get_high_score()
	if score > best:
		var date_str = Time.get_date_string_from_system()
		db.query(
			"UPDATE highscores SET max_score = %d, date = '%s' WHERE id = 1" % [score, date_str]
		)
		return true
	return false
