extends Node2D

# Partridge Hunter - multiplayer-ready gameplay foundation.
# Networking, voice chat and backend matchmaking will be connected in later builds.

var score := 0
var ammo := 8
var hunter_name := "صياد"
var selected_shell := 12
var target := Vector2(360, 620)
var dog_name := "كلب الصيد"
var dog_searching := false
var rng := RandomNumberGenerator.new()

var shell_sizes = [12, 16, 20]

func _ready():
    rng.randomize()
    target = _new_target()
    queue_redraw()

func _new_target() -> Vector2:
    return Vector2(rng.randf_range(80, 640), rng.randf_range(300, 1050))

func _unhandled_input(event):
    if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
        var p = event.position

        # Bottom controls: shell selector and dog command.
        if p.y > 1080 and p.x < 260:
            selected_shell = shell_sizes[(shell_sizes.find(selected_shell) + 1) % shell_sizes.size()]
            queue_redraw()
            return

        if p.y > 1080 and p.x >= 260 and p.x < 520:
            dog_searching = true
            queue_redraw()
            return

        if ammo <= 0:
            ammo = 8
        elif p.distance_to(target) < 75:
            score += 10 + (20 - selected_shell)
            ammo -= 1
            dog_searching = false
            target = _new_target()
        else:
            ammo -= 1
        queue_redraw()

func _draw():
    draw_rect(Rect2(0,0,720,1280), Color("#76ad5d"))
    draw_rect(Rect2(0,0,720,190), Color("#79b7d9"))
    draw_rect(Rect2(0,0,720,110), Color("#173f2b"))

    draw_string(ThemeDB.fallback_font, Vector2(25,45), "PARTRIDGE HUNTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(25,85), "صيد الحجل - Multiplayer", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d9f99d"))
    draw_string(ThemeDB.fallback_font, Vector2(500,45), "النقاط: "+str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(500,80), "الطلقات: "+str(ammo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffe08a"))

    draw_string(ThemeDB.fallback_font, Vector2(25,145), "الصياد: "+hunter_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(25,175), "الخرطوش: نمرة "+str(selected_shell), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(390,145), "الكلب: "+dog_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

    # Partridge target.
    draw_circle(target, 48, Color("#6b4226"))
    draw_circle(target + Vector2(-28,-22), 23, Color("#80502d"))
    draw_circle(target + Vector2(-43,-27), 7, Color.BLACK)
    draw_circle(target + Vector2(-45,-29), 3, Color.WHITE)

    if dog_searching:
        draw_string(ThemeDB.fallback_font, Vector2(210,1040), dog_name+" يبحث عن الطريدة...", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#fff0a8"))

    draw_string(ThemeDB.fallback_font, Vector2(145,1160), "اللمس على الطريدة = إطلاق النار", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_rect(Rect2(20,1090,210,70), Color("#294f32"))
    draw_rect(Rect2(255,1090,250,70), Color("#294f32"))
    draw_rect(Rect2(525,1090,175,70), Color("#294f32"))
    draw_string(ThemeDB.fallback_font, Vector2(45,1135), "خرطوش "+str(selected_shell), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(285,1135), "🐕 أمر: ابحث", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(555,1135), "🎙️ صوت", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
