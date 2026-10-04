extends Node3D

var manager: MatchManager
var characters := [
    ["kael", "BLUE", Vector3(-8, 1, 15), false],
    ["orion", "BLUE", Vector3(0, 1, 17), true],
    ["nyx", "BLUE", Vector3(8, 1, 15), true],
    ["jax", "RED", Vector3(-8, 1, -15), true],
    ["zuri", "RED", Vector3(0, 1, -17), true],
    ["kage", "RED", Vector3(8, 1, -15), true]
]

func _ready():
    manager = MatchManager.new()
    add_child(manager)
    _build_arena()
    _build_spawns()
    _build_objectives()
    _build_powerups()
    _build_characters()
    var ui = $UI
    ui.setup(manager)

func _build_arena():
    var ground = MeshInstance3D.new()
    var mesh = BoxMesh.new()
    mesh.size = Vector3(46, 1, 70)
    ground.mesh = mesh
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#202832")
    ground.material_override = mat
    ground.position.y = -0.5
    add_child(ground)

    for x in [-12.0, 12.0]:
        var wall = MeshInstance3D.new()
        var wmesh = BoxMesh.new()
        wmesh.size = Vector3(2, 3, 70)
        wall.mesh = wmesh
        wall.position = Vector3(x, 1.0, 0)
        var wmat = StandardMaterial3D.new()
        wmat.albedo_color = Color("#303945")
        wall.material_override = wmat
        add_child(wall)

    var env = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#070b12")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#8090b0")
    environment.ambient_light_energy = 0.7
    env.environment = environment
    add_child(env)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -25, 0)
    sun.light_energy = 1.1
    add_child(sun)

func _build_spawns():
    for team in ["blue", "red"]:
        var marker = Marker3D.new()
        marker.name = team + "_spawn"
        marker.position = Vector3(0, 1, 19 if team == "blue" else -19)
        marker.add_to_group("spawn_" + team)
        add_child(marker)

func _build_objectives():
    _spawn_objective("BLUE", "TARGET_A", Vector3(-8, 1.5, 23), false)
    _spawn_objective("BLUE", "TARGET_B", Vector3(8, 1.5, 23), false)
    _spawn_objective("BLUE", "MAIN_TOWER", Vector3(0, 2, 28), true)
    _spawn_objective("RED", "TARGET_A", Vector3(-8, 1.5, -23), false)
    _spawn_objective("RED", "TARGET_B", Vector3(8, 1.5, -23), false)
    _spawn_objective("RED", "MAIN_TOWER", Vector3(0, 2, -28), true)

func _spawn_objective(team, id, pos, main):
    var obj = preload("res://scripts/objective.gd").new()
    obj.position = pos
    obj.setup(team, id, main)
    if main:
        obj.add_to_group("main_" + team.to_lower())
    add_child(obj)

func _build_powerups():
    var spots = [
        [Vector3(-6, 1, 8), 0],
        [Vector3(6, 1, 8), 1],
        [Vector3(0, 1, 0), 2],
        [Vector3(-6, 1, -8), 3],
        [Vector3(6, 1, -8), 0]
    ]
    for data in spots:
        var p = preload("res://scripts/powerup.gd").new()
        p.position = data[0]
        p.setup(data[1])
        add_child(p)

func _build_characters():
    for data in characters:
        var c = preload("res://scripts/character.gd").new()
        c.position = data[2]
        c.setup(data[0], data[1], data[3])
        add_child(c)
        c.add_to_group("combat_targets")
        if not data[3]:
            c.add_to_group("human_player")
            var cam = Camera3D.new()
            cam.set_script(preload("res://scripts/camera.gd"))
            cam.position = Vector3(0, 22, 16)
            cam.rotation_degrees = Vector3(-55, 0, 0)
            c.add_child(cam)
            cam.make_current()
