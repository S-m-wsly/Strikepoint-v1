extends CanvasLayer
class_name StrikeUI

@onready var timer_label = $HUD/TopBar/Timer
@onready var blue_score_label = $HUD/TopBar/BlueScore
@onready var red_score_label = $HUD/TopBar/RedScore
@onready var objective_label = $HUD/ObjectiveState
@onready var announcement_label = $HUD/Announcement
@onready var end_panel = $HUD/EndPanel
@onready var end_label = $HUD/EndPanel/Result
@onready var restart_button = $HUD/EndPanel/Restart
var match_manager: MatchManager
var reloading := false

func _ready():
    var touch = preload("res://scripts/touch_controls.gd").new()
    $HUD.add_child(touch)

func setup(manager):
    match_manager = manager
    manager.hud_changed.connect(refresh)
    manager.announcement.connect(show_announcement)
    manager.match_finished.connect(show_result)
    refresh()

func refresh():
    if not match_manager:
        return
    timer_label.text = match_manager.get_time_text()
    blue_score_label.text = "BLUE  %02d" % match_manager.blue_score
    red_score_label.text = "RED  %02d" % match_manager.red_score
    objective_label.text = "BLUE: %d/2    MAIN %s        RED: %d/2    MAIN %s" % [
        match_manager.blue_targets_destroyed,
        "OPEN" if match_manager.blue_main_unlocked else "LOCKED",
        match_manager.red_targets_destroyed,
        "OPEN" if match_manager.red_main_unlocked else "LOCKED"
    ]

func show_announcement(text):
    announcement_label.text = text
    announcement_label.visible = true
    await get_tree().create_timer(2.5).timeout
    if is_instance_valid(announcement_label) and announcement_label.text == text:
        announcement_label.visible = false

func show_result(winner):
    end_panel.visible = true
    if winner == "DRAW":
        end_label.text = "DRAW"
    else:
        end_label.text = winner + " TEAM\nVICTORY"

# Touch (and mouse-emulated touch) restart. Keyboard: R.
func _input(event):
    if not end_panel.visible or reloading:
        return
    var hit := false
    if event is InputEventScreenTouch and event.pressed:
        hit = restart_button.get_global_rect().has_point(event.position)
    elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
        hit = true
    if hit:
        reloading = true
        get_tree().reload_current_scene()
