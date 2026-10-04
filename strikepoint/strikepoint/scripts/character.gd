extends CharacterBody3D
class_name StrikeCharacter

const BAR_W := 1.4

var character_id := "kael"
var team := "BLUE"
var stats: Dictionary
var hp := 100.0
var level := 1
var xp := 0.0
var spawn_invulnerable := 0.0
var armor_time := 0.0
var cooldowns := [0.0, 0.0, 0.0]
var attack_cooldown := 0.0
var retarget_time := 0.0
var target: Node3D
var is_ai := true
var dead := false
var display_name := "KAEL"
var virtual_move := Vector2.ZERO
var virtual_attack := false
var collider: CollisionShape3D
var hp_fill: MeshInstance3D
var manager: MatchManager

func setup(id: String, team_id: String, ai := true):
    character_id = id
    team = team_id
    is_ai = ai
    display_name = id.to_upper()
    stats = GameBalance.character_stats(character_id)
    hp = stats.health
    _build_body()

func _ready():
    manager = get_tree().get_first_node_in_group("match_manager") as MatchManager

func _build_body():
    var team_color := Color("#2d8cff") if team == "BLUE" else Color("#ef3340")
    var body_mesh = MeshInstance3D.new()
    var capsule = CapsuleMesh.new()
    capsule.height = 1.8
    capsule.radius = 0.45
    body_mesh.mesh = capsule
    var mat = StandardMaterial3D.new()
    mat.albedo_color = team_color
    mat.emission_enabled = true
    mat.emission = team_color * 0.18
    body_mesh.material_override = mat
    add_child(body_mesh)
    # Head in the character's own color so each hero is recognisable.
    var head = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.32
    sphere.height = 0.64
    head.mesh = sphere
    var hmat = StandardMaterial3D.new()
    hmat.albedo_color = stats.color
    hmat.emission_enabled = true
    hmat.emission = stats.color * 0.4
    head.material_override = hmat
    head.position = Vector3(0, 1.15, 0)
    add_child(head)
    collider = CollisionShape3D.new()
    var shape = CapsuleShape3D.new()
    shape.height = 1.8
    shape.radius = 0.45
    collider.shape = shape
    add_child(collider)
    var label = Label3D.new()
    label.text = display_name
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.pixel_size = 0.008
    label.font_size = 48
    label.outline_size = 10
    label.modulate = team_color.lightened(0.4)
    label.position = Vector3(0, 2.35, 0)
    add_child(label)
    _quad(Vector2(BAR_W + 0.06, 0.2), Color.BLACK, 1.9, 1)
    hp_fill = _quad(Vector2(BAR_W, 0.14), team_color, 1.9, 2)

func _quad(size: Vector2, c: Color, y: float, prio: int) -> MeshInstance3D:
    var q := QuadMesh.new()
    q.size = size
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    m.billboard_keep_scale = true
    m.no_depth_test = true
    m.render_priority = prio
    var mi := MeshInstance3D.new()
    mi.mesh = q
    mi.material_override = m
    mi.position.y = y
    add_child(mi)
    return mi

func _physics_process(delta):
    if dead:
        return
    if manager and manager.finished:
        velocity = Vector3.ZERO
        return
    spawn_invulnerable = maxf(0.0, spawn_invulnerable - delta)
    armor_time = maxf(0.0, armor_time - delta)
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    for i in 3:
        cooldowns[i] = maxf(0.0, cooldowns[i] - delta)

    if is_ai:
        _ai_tick(delta)
    else:
        _player_tick()

    velocity.y = 0.0
    if velocity.length() > 0.01:
        move_and_slide()
    global_position.x = clampf(global_position.x, -21.0, 21.0)
    global_position.z = clampf(global_position.z, -33.0, 33.0)
    var ratio := clampf(hp / stats.health, 0.0, 1.0)
    hp_fill.scale.x = maxf(ratio, 0.001)
    hp_fill.position.x = -BAR_W * (1.0 - ratio) * 0.5

func _player_tick():
    var keyboard_move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var input_move := keyboard_move if keyboard_move.length() > 0.05 else virtual_move
    if input_move.length() > 0.05:
        velocity = Vector3(input_move.x, 0, input_move.y).limit_length(1.0) * stats.speed
    else:
        velocity = Vector3.ZERO
    if Input.is_action_pressed("attack") or virtual_attack:
        basic_attack(_find_target(true))
    if Input.is_action_just_pressed("ability_1"):
        use_ability(0)
    if Input.is_action_just_pressed("ability_2"):
        use_ability(1)
    if Input.is_action_just_pressed("ability_3"):
        use_ability(2)

func _ai_tick(delta):
    retarget_time -= delta
    if not _valid_target(target) or retarget_time <= 0.0:
        target = _find_target()
        retarget_time = 0.5
    if not _valid_target(target):
        velocity = Vector3.ZERO
        return
    var dist = global_position.distance_to(target.global_position)
    var direction = target.global_position - global_position
    direction.y = 0
    direction = direction.normalized()
    if dist > stats.reach * 0.85:
        velocity = direction * stats.speed
    else:
        velocity = Vector3.ZERO
        basic_attack(target)
        for i in 3:
            if cooldowns[i] <= 0.0 and dist <= [4.0, 5.0, 6.0][i]:
                use_ability(i)

func _valid_target(t) -> bool:
    if not is_instance_valid(t):
        return false
    if t is StrikeCharacter:
        return not t.dead
    if t is StrikeObjective:
        return not t.destroyed and t.unlocked
    return false

# AI: fight enemies that are close, otherwise push objectives, otherwise chase enemies.
# Player (range_only = true): nearest valid thing inside weapon range, heroes first.
func _find_target(range_only := false) -> Node3D:
    var best_char: Node3D = null
    var best_char_d := INF
    var best_obj: Node3D = null
    var best_obj_d := INF
    for node in get_tree().get_nodes_in_group("combat_targets"):
        if node == self or not (node is Node3D) or node.team == team:
            continue
        if not _valid_target(node):
            continue
        var d := global_position.distance_to(node.global_position)
        if range_only and d > stats.reach + 1.0:
            continue
        if node is StrikeCharacter:
            if d < best_char_d:
                best_char = node
                best_char_d = d
        elif d < best_obj_d:
            best_obj = node
            best_obj_d = d
    if best_char and (range_only or best_char_d <= 10.0):
        return best_char
    if best_obj:
        return best_obj
    return best_char

func basic_attack(victim: Node):
    if attack_cooldown > 0.0 or not _valid_target(victim):
        return
    if global_position.distance_to(victim.global_position) > stats.reach + 1.0:
        return
    attack_cooldown = GameBalance.ATTACK_COOLDOWN
    spawn_invulnerable = 0.0
    victim.take_damage(stats.damage, self)

func use_ability(index: int):
    if dead or index < 0 or index > 2 or cooldowns[index] > 0.0:
        return
    cooldowns[index] = [7.0, 10.0, 14.0][index]
    spawn_invulnerable = 0.0
    var radius = [4.0, 5.0, 6.0][index]
    var multiplier = [1.4, 1.0, 1.8][index]
    for node in get_tree().get_nodes_in_group("combat_targets"):
        if node == self or node.team == team:
            continue
        if _valid_target(node) and global_position.distance_to(node.global_position) <= radius:
            node.take_damage(stats.damage * multiplier, self)

func take_damage(amount: float, source: Node = null):
    if dead or spawn_invulnerable > 0.0:
        return
    if armor_time > 0.0:
        amount *= 0.8
    hp -= amount
    if hp <= 0.0:
        _die(source)

func heal(amount: float):
    hp = minf(stats.health, hp + amount)

func add_xp(amount: float):
    xp += amount
    if xp >= 100 and level < 3:
        xp -= 100
        level += 1
        stats.health *= 1.05
        stats.damage *= 1.05
        hp = stats.health

func _die(killer):
    dead = true
    hp = 0.0
    target = null
    visible = false
    velocity = Vector3.ZERO
    collider.set_deferred("disabled", true)
    if manager:
        manager.register_kill(killer, self)
    await get_tree().create_timer(GameBalance.RESPAWN_TIME).timeout
    if not is_inside_tree() or (manager and manager.finished):
        return
    var spawn = get_tree().get_first_node_in_group("spawn_" + team.to_lower())
    if spawn:
        global_position = spawn.global_position + Vector3(randf_range(-6.0, 6.0), 0, 0)
    hp = stats.health
    armor_time = 0.0
    dead = false
    visible = true
    collider.set_deferred("disabled", false)
    spawn_invulnerable = GameBalance.SPAWN_PROTECTION
