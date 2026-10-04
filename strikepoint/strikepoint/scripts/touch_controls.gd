extends Control
class_name TouchControls
## Multi-touch controls: floating joystick on the left, buttons on the right.
## Uses raw touch events so the player can move and attack with two fingers at once.

const JOY_RADIUS := 90.0
var fingers := {}          # touch index -> button id
var joy_finger := -1
var joy_origin := Vector2.ZERO
var joy_pos := Vector2.ZERO
var player: StrikeCharacter

func _ready():
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _buttons() -> Array:
    var s := get_viewport_rect().size
    return [
        {"id": "atk", "pos": Vector2(s.x - 130, s.y - 130), "r": 75.0, "text": "ATTACK"},
        {"id": "ab0", "pos": Vector2(s.x - 300, s.y - 80), "r": 45.0, "text": "1"},
        {"id": "ab1", "pos": Vector2(s.x - 270, s.y - 195), "r": 45.0, "text": "2"},
        {"id": "ab2", "pos": Vector2(s.x - 140, s.y - 290), "r": 45.0, "text": "3"}]

func _find_player():
    if is_instance_valid(player):
        return
    var found = get_tree().get_nodes_in_group("human_player")
    if found.size() > 0:
        player = found[0]

func _process(_delta):
    _find_player()
    queue_redraw()

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            _press(event.index, event.position)
        else:
            _release(event.index)
    elif event is InputEventScreenDrag and event.index == joy_finger:
        _drag(event.position)

func _press(index: int, p: Vector2):
    for b in _buttons():
        if p.distance_to(b.pos) <= b.r * 1.25:
            fingers[index] = b.id
            _fire(b.id, true)
            return
    if joy_finger == -1 and p.x < get_viewport_rect().size.x * 0.5:
        joy_finger = index
        joy_origin = p
        joy_pos = p

func _release(index: int):
    if fingers.has(index):
        _fire(fingers[index], false)
        fingers.erase(index)
    if index == joy_finger:
        joy_finger = -1
        if is_instance_valid(player):
            player.virtual_move = Vector2.ZERO

func _drag(p: Vector2):
    var v := (p - joy_origin).limit_length(JOY_RADIUS)
    joy_pos = joy_origin + v
    if is_instance_valid(player):
        player.virtual_move = v / JOY_RADIUS

func _fire(id: String, down: bool):
    if not is_instance_valid(player):
        return
    if id == "atk":
        player.virtual_attack = down
    elif down:
        player.use_ability(int(id.substr(2)))

func _draw():
    var font := ThemeDB.fallback_font
    var base := joy_origin if joy_finger != -1 else Vector2(150, get_viewport_rect().size.y - 150)
    var knob := joy_pos if joy_finger != -1 else base
    draw_circle(base, JOY_RADIUS, Color(1, 1, 1, 0.12))
    draw_arc(base, JOY_RADIUS, 0.0, TAU, 40, Color(1, 1, 1, 0.35), 3.0)
    draw_circle(knob, 38.0, Color(1, 1, 1, 0.35))
    for b in _buttons():
        var down: bool = fingers.values().has(b.id)
        draw_circle(b.pos, b.r, Color(0.9, 0.2, 0.25, 0.6) if down else Color(0.1, 0.12, 0.2, 0.55))
        draw_arc(b.pos, b.r, 0.0, TAU, 40, Color(1, 1, 1, 0.5), 3.0)
        var text: String = b.text
        if b.id.begins_with("ab") and is_instance_valid(player):
            var cd: float = player.cooldowns[int(b.id.substr(2))]
            if cd > 0.0:
                text = str(ceili(cd))
        var fs := 22 if b.id == "atk" else 28
        draw_string(font, b.pos + Vector2(-b.r, fs * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, b.r * 2.0, fs)
