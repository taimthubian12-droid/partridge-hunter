extends Node2D

var score = 0
var ammo = 8
var target = Vector2(360, 620)
var rng = RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    _new_target()
    update()

func _new_target():
    target = Vector2(rng.randf_range(80, 640), rng.randf_range(220, 1040))

func _input(event):
    if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
        if ammo <= 0:
            ammo = 8
        elif event.position.distance_to(target) < 78:
            score += 10
            ammo -= 1
            _new_target()
        else:
            ammo -= 1
        update()

func _draw():
    draw_rect(Rect2(0, 0, 720, 1280), Color("#76ad5d"))
    draw_rect(Rect2(0, 0, 720, 190), Color("#79b7d9"))
    draw_rect(Rect2(0, 0, 720, 110), Color("#173f2b"))
    draw_string(get_font("font"), Vector2(500, 45), "النقاط: " + str(score), Color.white)
    draw_string(get_font("font"), Vector2(500, 82), "الطلقات: " + str(ammo), Color("#ffe08a"))
    draw_circle(target, 48, Color("#6b4226"))
    draw_circle(target + Vector2(-28, -22), 23, Color("#80502d"))
    draw_circle(target + Vector2(-43, -27), 7, Color.black)
    draw_circle(target + Vector2(-45, -29), 3, Color.white)
