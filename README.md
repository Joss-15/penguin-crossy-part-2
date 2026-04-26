# 🐧 Penguin Crossy 2

> *"Penqüi regresa — ahora más rápido, más peligroso y con estrellas que recoger."*

![Gameplay Screenshot](screenshot.png)

---

## 📖 Descripción General

**Penguin Crossy 2** es un juego 3D de estilo *voxel* inspirado en Crossy Road, desarrollado en **Godot Engine 4.6** como continuación de la Práctica 7.

El jugador controla a **Penqüi**, un pingüino que debe esquivar una manada de pingüinos autónomos que patrullan el escenario a alta velocidad, mientras recoge estrellas doradas que aparecen aleatoriamente en el campo. El juego es **infinito** — las estrellas nunca dejan de aparecer — y el objetivo es acumular la mayor puntuación posible antes de ser golpeado.

Cada partida guarda la puntuación máxima histórica en una **base de datos local SQLite**, y al recoger una estrella se consulta una **API externa** que muestra un consejo aleatorio y puede provocar que los NPCs aceleren temporalmente.

---

## 🎮 Controles de Movimiento

| Tecla | Acción |
|-------|--------|
| `W` / `↑` | Avanzar |
| `S` / `↓` | Retroceder |
| `A` / `←` | Moverse a la izquierda |
| `D` / `→` | Moverse a la derecha |

> Penqüi se orienta automáticamente hacia la dirección de movimiento. No hay salto.

---

## ⭐ Coleccionables

Las **estrellas doradas** son esferas brillantes que flotan y rotan sobre el escenario. Aparecen de dos formas:

- **Al inicio:** 7 estrellas distribuidas manualmente en posiciones estratégicas dentro del área de los NPCs.
- **Durante la partida:** cada **1 segundo** aparece automáticamente una nueva estrella en una posición aleatoria dentro del rango del escenario (X: -7 a 7, Z: -8.3 a -3.5).

### ¿Qué pasa al recoger una estrella?
1. La estrella desaparece con un **sonido de recolección**.
2. El **contador de estrellas** en pantalla aumenta en 1 (`⭐ Estrellas: X`).
3. Se consulta la **API externa** para obtener un consejo aleatorio.
4. Si el consejo tiene un ID par, los **NPCs aceleran** temporalmente durante 5 segundos.
5. Si la puntuación supera el récord guardado al final de la partida, la base de datos se actualiza.

> El contador **no se reinicia** al ser golpeado por un NPC — las estrellas acumuladas en la sesión se conservan hasta el Game Over.

---

## 🤖 Los NPCs: La Manada

El escenario tiene **5 pingüinos autónomos** organizados en carriles horizontales muy juntos entre sí, diseñados para dificultar el paso de Penqüi:

| NPC | Carril (Z) | Velocidad | Carácter |
|-----|-----------|-----------|----------|
| Patrullero 1 | -3.5 | 7.0 u/s | El ansioso — no para nunca |
| Patrullero 2 | -4.7 | 6.0 u/s | El constante — lento pero imparable |
| Patrullero 3 | -5.9 | 8.0 u/s | El rápido — el más difícil de esquivar |
| Patrullero 4 | -7.1 | 6.5 u/s | El decidido — preciso y peligroso |
| Patrullero 5 | -8.3 | 9.0 u/s | El caótico — el más veloz del grupo |

### Comportamiento
- Se desplazan en **línea recta de izquierda a derecha** dentro de su carril y rebotan en los extremos.
- La detección de colisión es **omnidireccional** (Area3D) — Penqüi es golpeado sin importar desde qué lado toque al NPC.
- Al ser golpeado, Penqüi **regresa a su posición inicial** y el contador de intentos aumenta.
- Con el **speed boost de la API**, todos los NPCs multiplican su velocidad por 3x durante 5 segundos.

---

## 💾 Base de Datos Local (SQLite)

El juego utiliza el plugin **godot-sqlite** para guardar el historial de puntuaciones en un archivo local:

```
user://game_data.db
```

### Tabla: `highscores`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | INTEGER PRIMARY KEY | Identificador único |
| `player_name` | TEXT | Nombre del jugador (por defecto: "Jugador") |
| `max_score` | INTEGER | Puntuación máxima histórica |
| `date` | TEXT | Fecha de la última actualización |

### ¿Cómo se usa?
- Al **iniciar** el juego, se lee el récord guardado y se muestra en pantalla (`🏆 Récord: X`).
- Al **terminar** la partida (por colisión con un NPC), si la puntuación actual supera el récord guardado, se actualiza el registro automáticamente.
- La pantalla de Game Over muestra el récord actualizado y un mensaje `🌟 ¡Nuevo récord!` si fue superado.

---

## 🌐 API Externa: Advice Slip API

| Campo | Detalle |
|-------|---------|
| **Nombre** | Advice Slip API |
| **URL** | `https://api.adviceslip.com/advice` |
| **Tipo** | REST, GET, pública y gratuita (sin clave) |
| **Formato** | JSON |

### ¿Cómo afecta al juego?

Cada vez que Penqüi recoge una estrella, el juego hace una petición a la API usando el nodo `HTTPRequest` de Godot. La respuesta incluye un consejo aleatorio y un ID numérico:

- **Siempre:** el consejo se muestra en pantalla durante 5 segundos en la esquina inferior izquierda (`💡 [consejo]`).
- **Si el ID del consejo es par:** se activa un **speed boost** — todos los NPCs triplican su velocidad durante 5 segundos. En pantalla aparece el mensaje `⚡ ¡Evento! Los NPCs aceleran 5 segundos...`.
- **Si el ID es impar:** solo se muestra el consejo, sin efecto adicional.

### Ejemplo de respuesta JSON:
```json
{
  "slip": {
    "id": 42,
    "advice": "Don't forget to look both ways before crossing the road."
  }
}
```

---

## 💥 Sistema de Game Over

La partida termina cuando Penqüi es golpeado por un NPC (en modo estándar). Al terminar:

1. Todos los NPCs y el jugador se **detienen**.
2. Se muestra el panel de **Game Over** con la puntuación final y el récord histórico.
3. Si se superó el récord, se guarda automáticamente en la base de datos.
4. El botón **"🔄 Jugar de nuevo"** reinicia la escena completamente.

---

## 🗂️ Estructura del Proyecto

```
penguin-crossy part 2/
├── scenes/
│   ├── Level.tscn          # Escena principal del nivel
│   ├── Player.tscn         # Personaje jugable (Penqüi)
│   ├── NPC.tscn            # Plantilla de NPC reutilizable
│   ├── Collectible.tscn    # Estrella coleccionable
│   ├── player.gd           # Movimiento, colisiones y señales del jugador
│   ├── npc.gd              # IA del NPC (patrullaje A→B)
│   ├── collectible.gd      # Rotación, flotado, sonido y recolección
│   ├── level.gd            # Spawn de monedas, boost de velocidad, game over
│   ├── HUD.gd              # Interfaz: score, récord, mensajes, game over panel
│   ├── database.gd         # Autoload — gestión de SQLite
│   └── api_manager.gd      # Autoload — peticiones a Advice Slip API
├── assets/
│   ├── models/
│   │   ├── penguin/        # Modelo 3D de Penqüi (.glb)
│   │   ├── penguin npc/    # Modelo 3D del NPC (.glb)
│   │   ├── floor/          # Modelo 3D del escenario (.glb)
│   │   ├── Tree.glb
│   │   ├── Grass1.glb
│   │   └── Rock1.glb
│   └── sounds/
│       └── pick-up.mp3     # Sonido al recoger una estrella
├── screenshot.png
└── project.godot
```

---

## ⚙️ Tecnologías

| Herramienta | Uso |
|---|---|
| Godot Engine 4.6 | Motor del juego |
| GDScript | Lenguaje de scripting |
| Blender → `.glb` | Modelado 3D del personaje y escenario |
| godot-sqlite | Plugin para base de datos local SQLite |
| Advice Slip API | API REST pública para consejos aleatorios |
| HTTPRequest (Godot) | Nodo para peticiones asíncronas a la API |

---

## 🔗 Repositorio

> 🔗 [Enlace al repositorio en GitHub](#)  
> 

---

*Programación 3D — 8vo Semestre · Ingeniería · 2026A*
