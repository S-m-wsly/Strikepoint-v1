extends Area3D
class_name StrikePowerup

enum Kind { HEALTH, SPEED, DAMAGE, ARMOR, ABILITY }
const NAMES := ["HEALTH", "SPEED", "DAMAGE", "ARMOR", "ABILITY"]
var kind := Kind.HEALTH
var active := true

func setup(k: int):
    kind = k
    monitoring = true
    var mesh = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 0.45
    sphere.height = 0.9
    mesh.mesh = sphere
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#b52dff")
    mat.emission_enabled = true
    mat.emission = Color("#d05cff")
    mat.emission_energy_multiplier = 3.0
    mesh.material_override = mat
    add_child(mesh)
    var shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = 1.0
    shape.shape = sphere_shape
    add_child(shape)
    var label = Label3D.new()
    label.text = NAMES[kind]
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.pixel_size = 0.01
    label.font_size = 40
    label.outline_size = 10
    label.modulate = Color("#e6a8ff")
    label.position = Vector3(0, 1.1, 0)
    add_child(label)
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if not active or not (body is StrikeCharacter) or body.dead:
        return
    active = false
    visible = false
    match kind:
        Kind.HEALTH: body.heal(body.stats.health * 0.30)
        Kind.SPEED: _buff(body, "speed", 1.2)
        Kind.DAMAGE: _buff(body, "damage", 1.2)
        Kind.ARMOR: body.armor_time = GameBalance.POWERUP_DURATION
        Kind.ABILITY: body.cooldowns = [0.0, 0.0, 0.0]
    await get_tree().create_timer(GameBalance.POWERUP_RESPAWN).timeout
    active = true
    visible = true

func _buff(body, key: String, mult: float):
    body.stats[key] *= mult
    await get_tree().create_timer(GameBalance.POWERUP_DURATION).timeout
    if is_instance_valid(body):
        body.stats[key] /= mult
