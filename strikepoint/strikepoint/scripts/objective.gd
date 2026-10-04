extends StaticBody3D
class_name StrikeObjective

var team := "BLUE"
var objective_id := "TARGET_A"
var max_hp := GameBalance.TARGET_HP
var hp := GameBalance.TARGET_HP
var unlocked := true:
    set(value):
        unlocked = value
        _refresh_label()
var destroyed := false
var is_main := false
var label: Label3D

func setup(team_id: String, id: String, main := false):
    team = team_id
    objective_id = id
    is_main = main
    max_hp = GameBalance.MAIN_TOWER_HP if main else GameBalance.TARGET_HP
    hp = max_hp
    unlocked = not main
    add_to_group("combat_targets")
    _build_visual()

func _build_visual():
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(2.2, 3.0 if is_main else 2.0, 2.2)
    mesh.mesh = box
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color("#2878ff") if team == "BLUE" else Color("#d62f3d")
    mat.emission_enabled = true
    mat.emission = mat.albedo_color * (0.25 if not is_main else 0.45)
    mesh.material_override = mat
    add_child(mesh)
    var col = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = box.size
    col.shape = shape
    add_child(col)
    label = Label3D.new()
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.pixel_size = 0.012
    label.font_size = 48
    label.outline_size = 12
    label.position = Vector3(0, 3.4 if is_main else 2.7, 0)
    add_child(label)
    _refresh_label()

func _refresh_label():
    if label == null:
        return
    var nm := objective_id.replace("_", " ")
    if unlocked:
        label.text = nm + "  " + str(int(ceil(hp / max_hp * 100.0))) + "%"
    else:
        label.text = nm + "\nLOCKED"

func take_damage(amount: float, source: Node = null):
    if destroyed or not unlocked:
        return
    hp -= amount
    var mgr = get_tree().get_first_node_in_group("match_manager")
    if mgr:
        mgr.register_objective_damage(source, self, amount)
    _refresh_label()
    if hp <= 0:
        destroyed = true
        hp = 0
        if mgr:
            mgr.objective_destroyed(self)
        queue_free()
