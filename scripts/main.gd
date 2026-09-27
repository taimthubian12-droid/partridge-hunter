extends Node2D

var score := 0
var ammo := 8
var target := Vector2(360, 620)
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    target = Vector2(rng.randf_range(80, 640), rng.randf_range(300, 1050))
    queue_redraw()

func _unhandled_input(event):
    if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
        if ammo <= 0:
            ammo = 8
        elif event.position.distance_to(target) < 75:
            score += 10
            ammo -= 1
            target = Vector2(rng.randf_range(80, 640), rng.randf_range(300, 1050))
        else:
            ammo -= 1
        queue_redraw()

func _draw():
    draw_rect(Rect2(0,0,720,1280), Color("#76ad5d"))
    draw_rect(Rect2(0,0,720,190), Color("#79b7d9"))
    draw_rect(Rect2(0,0,720,110), Color("#173f2b"))
    draw_string(ThemeDB.fallback_font, Vector2(25,45), "PARTRIDGE HUNTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(25,85), "صيد الحجل - Lite", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d9f99d"))
    draw_string(ThemeDB.fallback_font, Vector2(500,45), "النقاط: "+str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(500,80), "الطلقات: "+str(ammo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffe08a"))
    draw_circle(target, 48, Color("#6b4226"))
    draw_circle(target + Vector2(-28,-22), 23, Color("#80502d"))
    draw_circle(target + Vector2(-43,-27), 7, Color.BLACK)
    draw_circle(target + Vector2(-45,-29), 3, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(170,1160), "المس الحجل للتصويب وإطلاق النار", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
