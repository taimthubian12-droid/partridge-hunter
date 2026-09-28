extends Node2D

# Partridge Hunter - multiplayer foundation.
# Local Wi-Fi / hotspot uses ENet. Internet matchmaking and voice transport are separate systems.

const PORT := 7777
const MAX_PLAYERS := 8

var score := 0
var ammo := 8
var shots_fired := 0
var hits := 0
var streak := 0
var best_streak := 0
var hunter_name := "صياد"
var selected_shell := 12
var target := Vector2(360, 620)
var dog_name := "كلب الصيد"
var dog_searching := false
var dog_has_found_prey := false
var rng := RandomNumberGenerator.new()
var shell_sizes = [12, 16, 20]

var peer: ENetMultiplayerPeer
var connected := false
var is_host := false
var status_text := "جاهز — أنشئ غرفة أو انضم إليها"
var host_ip := "192.168.1.2"
var players: Dictionary = {}
var editing_name := false

func _ready():
    rng.randomize()
    target = _new_target()
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    players[multiplayer.get_unique_id()] = {"name": hunter_name, "score": score}
    queue_redraw()

func _new_target() -> Vector2:
    return Vector2(rng.randf_range(80, 640), rng.randf_range(300, 980))

func host_game():
    peer = ENetMultiplayerPeer.new()
    var err = peer.create_server(PORT, MAX_PLAYERS)
    if err != OK:
        status_text = "تعذر إنشاء الغرفة: " + str(err)
        queue_redraw()
        return
    multiplayer.multiplayer_peer = peer
    connected = true
    is_host = true
    status_text = "الغرفة جاهزة — أعطِ اللاعبين عنوان IP هذا الجهاز"
    _sync_local_player()
    queue_redraw()

func join_game(ip: String):
    ip = ip.strip_edges()
    if ip.is_empty():
        status_text = "أدخل عنوان IP للمضيف"
        queue_redraw()
        return
    peer = ENetMultiplayerPeer.new()
    var err = peer.create_client(ip, PORT)
    if err != OK:
        status_text = "تعذر الاتصال: " + str(err)
        queue_redraw()
        return
    multiplayer.multiplayer_peer = peer
    status_text = "جارٍ الاتصال بـ " + ip + "..."
    queue_redraw()

func leave_game():
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
    multiplayer.multiplayer_peer = null
    connected = false
    is_host = false
    players.clear()
    players[multiplayer.get_unique_id()] = {"name": hunter_name, "score": score}
    status_text = "تم الخروج من الغرفة"
    queue_redraw()

func _on_peer_connected(id: int):
    if multiplayer.is_server():
        _register_player.rpc_id(id, hunter_name)
    status_text = "اتصل لاعب جديد — العدد: " + str(multiplayer.get_peers().size() + 1)
    queue_redraw()

func _on_peer_disconnected(id: int):
    players.erase(id)
    status_text = "غادر لاعب — العدد: " + str(multiplayer.get_peers().size() + 1)
    queue_redraw()

func _on_connected_to_server():
    connected = true
    status_text = "تم الاتصال بالغرفة"
    _register_player.rpc_id(1, hunter_name)
    queue_redraw()

func _on_connection_failed():
    connected = false
    status_text = "فشل الاتصال. تأكد من IP وأن الجهازين على نفس Wi-Fi/نقطة الاتصال"
    queue_redraw()

func _on_server_disconnected():
    connected = false
    status_text = "انقطع اتصال المضيف"
    queue_redraw()

@rpc("any_peer", "reliable")
func _register_player(name: String):
    var id = multiplayer.get_remote_sender_id()
    players[id] = {"name": name.left(18), "score": 0}
    if multiplayer.is_server():
        _broadcast_players.rpc(players)

@rpc("authority", "reliable")
func _broadcast_players(state: Dictionary):
    players = state
    queue_redraw()

func _sync_local_player():
    players[multiplayer.get_unique_id()] = {"name": hunter_name, "score": score}
    if multiplayer.is_server():
        _broadcast_players.rpc(players)
    else:
        _register_player.rpc_id(1, hunter_name)

@rpc("any_peer", "reliable")
func _request_dog_search():
    if multiplayer.is_server():
        dog_searching = true
        dog_has_found_prey = false
        _set_dog_state.rpc(true, false)

@rpc("authority", "reliable")
func _set_dog_state(searching: bool, found: bool):
    dog_searching = searching
    dog_has_found_prey = found
    queue_redraw()

func _start_dog_search():
    dog_searching = true
    dog_has_found_prey = false
    if connected:
        if multiplayer.is_server():
            _set_dog_state.rpc(true, false)
        else:
            _request_dog_search.rpc_id(1)
    # The local gameplay loop represents the dog finding and returning the prey.
    get_tree().create_timer(1.5).timeout.connect(_dog_found_prey)

func _dog_found_prey():
    if not dog_searching:
        return
    dog_searching = false
    dog_has_found_prey = true
    status_text = dog_name + " وجد الطريدة وعاد بها"
    if connected and multiplayer.is_server():
        _set_dog_state.rpc(false, true)
    queue_redraw()

func _fire_at(point: Vector2):
    if ammo <= 0:
        ammo = 8
        status_text = "تمت إعادة تعبئة الخرطوش"
        queue_redraw()
        return
    ammo -= 1
    if point.distance_to(target) < 75:
        shots_fired += 1
        hits += 1
        streak += 1
        best_streak = maxi(best_streak, streak)
        var shell_bonus := 0
        if selected_shell == 12:
            shell_bonus = 8
        elif selected_shell == 16:
            shell_bonus = 5
        else:
            shell_bonus = 2
        var streak_bonus := mini(streak * 2, 20)
        score += 10 + shell_bonus + streak_bonus
        target = _new_target()
        dog_has_found_prey = false
        status_text = "إصابة! أطلق النار على الطريدة التالية"
        _sync_local_player()
    else:
        shots_fired += 1
        streak = 0
        status_text = "لم تصب الهدف — بدأت سلسلة جديدة"
    queue_redraw()

func _unhandled_input(event):
    if event is InputEventKey and event.pressed and editing_name:
        if event.keycode == KEY_BACKSPACE:
            hunter_name = hunter_name.left(max(0, hunter_name.length() - 1))
        elif event.keycode == KEY_ENTER:
            editing_name = false
            status_text = "تم حفظ اسم الصياد: " + hunter_name
            _sync_local_player()
        elif event.unicode > 31 and hunter_name.length() < 18:
            hunter_name += char(event.unicode)
        queue_redraw()
        return

    if not ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)):
        return

    var p = event.position

    # Name area.
    if p.y >= 185 and p.y < 245:
        editing_name = true
        status_text = "اكتب اسم الصياد ثم اضغط Enter"
        queue_redraw()
        return

    # Network controls.
    if p.y >= 250 and p.y < 320:
        if p.x < 350:
            host_game()
        else:
            join_game(host_ip)
        return

    # Shell selector.
    if p.y > 1080 and p.x < 230:
        selected_shell = shell_sizes[(shell_sizes.find(selected_shell) + 1) % shell_sizes.size()]
        queue_redraw()
        return

    # Dog command.
    if p.y > 1080 and p.x >= 230 and p.x < 500:
        _start_dog_search()
        return

    # Leave room.
    if p.y > 1080 and p.x >= 500:
        leave_game()
        return

    _fire_at(p)

func _draw():
    draw_rect(Rect2(0, 0, 720, 1280), Color("#76ad5d"))
    draw_rect(Rect2(0, 0, 720, 175), Color("#79b7d9"))
    draw_rect(Rect2(0, 0, 720, 110), Color("#173f2b"))

    draw_string(ThemeDB.fallback_font, Vector2(25, 45), "PARTRIDGE HUNTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(25, 85), "صيد الحجل - Multiplayer", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d9f99d"))
    draw_string(ThemeDB.fallback_font, Vector2(500, 45), "النقاط: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(500, 80), "الطلقات: " + str(ammo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffe08a"))
    var accuracy := 0.0 if shots_fired == 0 else (float(hits) / float(shots_fired)) * 100.0
    draw_string(ThemeDB.fallback_font, Vector2(25, 575), "الدقة: %d%%   السلسلة: %d   أفضل سلسلة: %d" % [roundi(accuracy), streak, best_streak], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#fff0a8"))

    draw_rect(Rect2(20, 185, 680, 55), Color("#294f32"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 221), "اسم الصياد: " + hunter_name + ("  [تعديل]" if editing_name else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)

    draw_rect(Rect2(20, 250, 330, 65), Color("#315d39"))
    draw_rect(Rect2(370, 250, 330, 65), Color("#315d39"))
    draw_string(ThemeDB.fallback_font, Vector2(45, 291), "إنشاء غرفة", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(395, 291), "انضمام للمضيف", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)

    draw_string(ThemeDB.fallback_font, Vector2(25, 355), "الحالة: " + status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fff0a8"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 385), "IP المضيف: " + host_ip + "   المنفذ: " + str(PORT), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)

    draw_string(ThemeDB.fallback_font, Vector2(25, 425), "اللاعبون: " + str(players.size()) + "/" + str(MAX_PLAYERS), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
    var y := 455.0
    for id in players:
        var data = players[id]
        draw_string(ThemeDB.fallback_font, Vector2(35, y), "• " + str(data.get("name", "صياد")), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
        y += 25.0
        if y > 545:
            break

    # Partridge.
    draw_circle(target, 48, Color("#6b4226"))
    draw_circle(target + Vector2(-28, -22), 23, Color("#80502d"))
    draw_circle(target + Vector2(-43, -27), 7, Color.BLACK)
    draw_circle(target + Vector2(-45, -29), 3, Color.WHITE)

    draw_string(ThemeDB.fallback_font, Vector2(200, 1015), "الكلب: " + dog_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    if dog_searching:
        draw_string(ThemeDB.fallback_font, Vector2(155, 1045), dog_name + " يبحث عن الطريدة...", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#fff0a8"))
    elif dog_has_found_prey:
        draw_string(ThemeDB.fallback_font, Vector2(120, 1045), dog_name + " وجد الطريدة وعاد بها", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#fff0a8"))

    draw_rect(Rect2(15, 1090, 205, 70), Color("#294f32"))
    draw_rect(Rect2(230, 1090, 270, 70), Color("#294f32"))
    draw_rect(Rect2(510, 1090, 195, 70), Color("#294f32"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 1135), "خرطوش " + str(selected_shell), HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(265, 1135), "🐕 ابحث عن الطريدة", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(545, 1135), "خروج", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
