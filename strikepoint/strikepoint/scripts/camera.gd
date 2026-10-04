extends Camera3D

func _process(_delta):
    var player = get_parent()
    if is_instance_valid(player):
        global_position = player.global_position + Vector3(0, 22, 16)
        look_at(player.global_position, Vector3.UP)
