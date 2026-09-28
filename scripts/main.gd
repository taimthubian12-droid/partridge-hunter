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

# Syrian hunting map: governorate -> area -> village. Names are gameplay locations,
# not claims that hunting is legally permitted there. The game treats these as fictionalized
# hunting zones and uses time/weather to change spawn difficulty.
const SYRIA_HUNTING_ZONES := {
    "دمشق": {"الغوطة": ["دوما", "حرستا", "كفربطنا"]},
    "ريف دمشق": {"القلمون": ["يبرود", "النبك", "دير عطية"], "الزبداني": ["الزبداني", "بلودان", "مضايا"]},
    "حمص": {"تدمر": ["تدمر", "القريتين", "مهين"], "الريف الغربي": ["تلدو", "الحواش", "مرمريتا"]},
    "حماة": {"مصياف": ["مصياف", "وادي العيون", "عين حلاقيم"], "الغاب": ["السقيلبية", "قلعة المضيق", "محردة"]},
    "اللاذقية": {"جبلة": ["جبلة", "بيت ياشوط", "قرفيص"], "الحفة": ["الحفة", "صلنفة", "سلمى"]},
    "طرطوس": {"صافيتا": ["صافيتا", "مشتى الحلو", "الدريكيش"], "بانياس": ["بانياس", "القدموس", "حمام القراحلة"]},
    "حلب": {"عفرين": ["عفرين", "راجو", "جنديرس"], "الريف الشمالي": ["اعزاز", "مارع", "تل رفعت"]},
    "إدلب": {"جسر الشغور": ["جسر الشغور", "بداما", "دركوش"], "معرة النعمان": ["معرة النعمان", "كفرنبل", "حزارين"]},
    "الرقة": {"تل أبيض": ["تل أبيض", "سلوك", "عين عيسى"], "الطبقة": ["الطبقة", "المنصورة", "الجرنية"]},
    "دير الزور": {"الميادين": ["الميادين", "ذيبان", "العشارة"], "البوكمال": ["البوكمال", "السوسة", "هجين"]},
    "الحسكة": {"القامشلي": ["القامشلي", "عامودا", "الدرباسية"], "المالكية": ["المالكية", "رميلان", "معبدة"]},
    "درعا": {"الريف الغربي": ["طفس", "جاسم", "نوى"], "الريف الشرقي": ["بصرى الشام", "الحراك", "المسيفرة"]},
    "القنيطرة": {"ريف القنيطرة": ["خان أرنبة", "جباتا الخشب", "مسعدة"]},
    "السويداء": {"جبل العرب": ["شهبا", "صلخد", "القريا"]}
}

var selected_governorate := "ريف دمشق"
var selected_area := "القلمون"
var selected_village := "يبرود"
var game_hour := 6.0
var weather := "صحو"
var wind_speed := 3.0
var temperature := 20.0
var weather_updated_at := ""
var weather_request: HTTPRequest
var weather_refresh_seconds := 900.0
var weather_refresh_timer := 0.0
var weather_request_busy := false
var partridge_speed := 1.0
var partridge_visible := true
var live_weather_enabled := true
var weather_code := 0
var precipitation_mm := 0.0
var daylight := true

# Representative coordinates for the selected gameplay area.
# Weather is fetched for the area; the village remains the player-facing sub-location.
const AREA_COORDINATES := {
    "دمشق|الغوطة": Vector2(33.55, 36.35), "ريف دمشق|القلمون": Vector2(33.80, 36.55), "ريف دمشق|الزبداني": Vector2(33.72, 36.10),
    "حمص|تدمر": Vector2(34.56, 38.28), "حمص|الريف الغربي": Vector2(34.75, 36.55), "حماة|مصياف": Vector2(35.07, 36.34),
    "حماة|الغاب": Vector2(35.45, 36.40), "اللاذقية|جبلة": Vector2(35.36, 35.93), "اللاذقية|الحفة": Vector2(35.60, 36.05),
    "طرطوس|صافيتا": Vector2(34.82, 36.12), "طرطوس|بانياس": Vector2(35.18, 35.95), "حلب|عفرين": Vector2(36.51, 36.87),
    "حلب|الريف الشمالي": Vector2(36.55, 37.15), "إدلب|جسر الشغور": Vector2(35.82, 36.32), "إدلب|معرة النعمان": Vector2(35.65, 36.67),
    "الرقة|تل أبيض": Vector2(36.70, 38.95), "الرقة|الطبقة": Vector2(35.84, 38.55), "دير الزور|الميادين": Vector2(35.02, 40.45),
    "دير الزور|البوكمال": Vector2(34.45, 40.92), "الحسكة|القامشلي": Vector2(37.05, 41.23), "الحسكة|المالكية": Vector2(37.18, 42.13),
    "درعا|الريف الغربي": Vector2(32.62, 36.00), "درعا|الريف الشرقي": Vector2(32.70, 36.25), "القنيطرة|ريف القنيطرة": Vector2(33.00, 35.95),
    "السويداء|جبل العرب": Vector2(32.70, 36.55)
}

var peer: ENetMultiplayerPeer
var connected := false
var is_host := false
var status_text := "جاهز — أنشئ غرفة أو انضم إليها"
var host_ip := "192.168.1.2"
var players: Dictionary = {}
var editing_name := false
var location_menu_open := false
var location_level := 0

func _ready():
    rng.randomize()
    _update_world_conditions()
    weather_request = HTTPRequest.new()
    add_child(weather_request)
    weather_request.request_completed.connect(_on_weather_request_completed)
    _request_live_weather()
    target = _new_target()
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    players[multiplayer.get_unique_id()] = {"name": hunter_name, "score": score}
    queue_redraw()


func _location_options() -> Array:
    if location_level == 0:
        return _governorates()
    if location_level == 1:
        return _areas()
    return _villages()

func _location_title() -> String:
    if location_level == 0:
        return "اختر المحافظة"
    if location_level == 1:
        return "اختر المنطقة — " + selected_governorate
    return "اختر القرية — " + selected_area

func _open_location_menu(level: int):
    location_menu_open = true
    location_level = level
    queue_redraw()

func _governorates() -> Array:
    return SYRIA_HUNTING_ZONES.keys()

func _areas() -> Array:
    return SYRIA_HUNTING_ZONES.get(selected_governorate, {}).keys()

func _villages() -> Array:
    return SYRIA_HUNTING_ZONES.get(selected_governorate, {}).get(selected_area, [])

func select_governorate(name: String):
    if not SYRIA_HUNTING_ZONES.has(name):
        return
    selected_governorate = name
    var areas = _areas()
    selected_area = areas[0] if areas.size() > 0 else ""
    var villages = _villages()
    selected_village = villages[0] if villages.size() > 0 else ""
    _update_world_conditions()
    weather_updated_at = ""
    _request_live_weather()
    status_text = "منطقة الصيد: %s / %s / %s" % [selected_governorate, selected_area, selected_village]
    queue_redraw()

func select_area(name: String):
    if not _areas().has(name):
        return
    selected_area = name
    var villages = _villages()
    selected_village = villages[0] if villages.size() > 0 else ""
    _update_world_conditions()
    weather_updated_at = ""
    _request_live_weather()
    queue_redraw()

func select_village(name: String):
    if not _villages().has(name):
        return
    selected_village = name
    _update_world_conditions()
    weather_updated_at = ""
    _request_live_weather()
    queue_redraw()

func _request_live_weather():
    if not live_weather_enabled or weather_request == null or weather_request_busy:
        return
    weather_request_busy = true
    var coords = AREA_COORDINATES.get(selected_governorate + "|" + selected_area, Vector2(33.51, 36.29))
    var url = "https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=temperature_2m,weather_code,wind_speed_10m,precipitation&daily=sunrise,sunset&timezone=auto" % [str(coords.x), str(coords.y)]
    var err = weather_request.request(url)
    if err != OK:
        weather_request_busy = false
        live_weather_enabled = false
        status_text = "تعذر تحديث الطقس — تعمل اللعبة بالوضع المحلي"

func _on_weather_request_completed(result, response_code, _headers, body):
    weather_request_busy = false
    if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
        status_text = "تعذر جلب الطقس — تم استخدام آخر حالة محفوظة"
        return
    var json = JSON.new()
    if json.parse(body.get_string_from_utf8()) != OK:
        return
    var data = json.data
    if typeof(data) != TYPE_DICTIONARY or not data.has("current"):
        return
    var current = data["current"]
    temperature = float(current.get("temperature_2m", temperature))
    wind_speed = float(current.get("wind_speed_10m", wind_speed))
    weather_code = int(current.get("weather_code", weather_code))
    precipitation_mm = float(current.get("precipitation", precipitation_mm))
    weather = _weather_name(weather_code)
    daylight = _is_daylight(data)
    weather_updated_at = str(current.get("time", ""))
    var local_time = str(current.get("time", ""))
    if local_time.contains("T"):
        var hm = local_time.split("T")[1].split(":")
        if hm.size() >= 2:
            game_hour = float(hm[0]) + float(hm[1]) / 60.0
    status_text = "الطقس مباشر: %s / %s" % [weather, selected_area]
    queue_redraw()

func _is_daylight(data: Dictionary) -> bool:
    if not data.has("daily"):
        return game_hour >= 6.0 and game_hour < 19.0
    var daily = data["daily"]
    if not daily.has("sunrise") or not daily.has("sunset"):
        return game_hour >= 6.0 and game_hour < 19.0
    var sunrise = str(daily["sunrise"][0]).split("T")
    var sunset = str(daily["sunset"][0]).split("T")
    if sunrise.size() < 2 or sunset.size() < 2:
        return game_hour >= 6.0 and game_hour < 19.0
    var sr = sunrise[1].split(":")
    var ss = sunset[1].split(":")
    var sunrise_hour = float(sr[0]) + float(sr[1]) / 60.0
    var sunset_hour = float(ss[0]) + float(ss[1]) / 60.0
    return game_hour >= sunrise_hour and game_hour <= sunset_hour

func _weather_name(code: int) -> String:
    if code == 0:
        return "صحو"
    if code <= 3:
        return "غائم جزئياً"
    if code == 45 or code == 48:
        return "ضباب"
    if code >= 51 and code <= 67:
        return "رذاذ/مطر"
    if code >= 71 and code <= 77:
        return "ثلوج"
    if code >= 80 and code <= 82:
        return "زخات مطر"
    if code >= 95:
        return "عاصفة رعدية"
    return "متغير"

func _update_world_conditions():
    # In-game clock follows a 24h cycle; later this can be fed by a live weather service.
    game_hour = fmod(Time.get_time_dict_from_system().hour + Time.get_time_dict_from_system().minute / 60.0, 24.0)
    var seasonal_seed = Time.get_date_dict_from_system().month
    var zone_factor = float(selected_governorate.length() + selected_area.length() + selected_village.length())
    temperature = 10.0 + (sin((float(seasonal_seed) / 12.0) * TAU - PI / 2.0) + 1.0) * 10.0 + fmod(zone_factor, 7.0)
    wind_speed = 1.5 + fmod(zone_factor * 0.7, 7.0)
    if int(zone_factor) % 9 == 0:
        weather = "غائم"
    elif int(zone_factor) % 13 == 0:
        weather = "ضباب خفيف"
    elif int(zone_factor) % 17 == 0:
        weather = "مطر خفيف"
    else:
        weather = "صحو"

func _world_difficulty() -> float:
    var difficulty = 1.0
    if not daylight:
        difficulty += 0.65
    if weather == "ضباب" or weather == "رذاذ/مطر" or weather == "زخات مطر":
        difficulty += 0.25
    if wind_speed >= 7.0:
        difficulty += 0.30
    return difficulty

func _update_partridge_behavior():
    partridge_visible = daylight
    partridge_speed = 1.0
    if game_hour < 7.0 or game_hour >= 17.0:
        partridge_speed += 0.20
    if weather == "ضباب" or weather == "رذاذ/مطر" or weather == "زخات مطر":
        partridge_speed -= 0.10
    if wind_speed >= 7.0:
        partridge_speed += 0.15
    partridge_speed = clampf(partridge_speed, 0.75, 1.5)

func _hunting_condition_text() -> String:
    var period = "فجر" if game_hour < 7.0 else ("صباح" if game_hour < 12.0 else ("بعد الظهر" if game_hour < 17.0 else ("غروب" if game_hour < 20.0 else "ليل")))
    var live = "مباشر" if live_weather_enabled and weather_updated_at != "" else "محلي"
    return "%s | %s | %s°C | رياح %.1f م/ث | %s" % [period, weather, temperature, wind_speed, live]

func _new_target() -> Vector2:
    var spread = 1.0 / _world_difficulty()
    if not partridge_visible:
        spread *= 0.55
    var center = Vector2(360, 620)
    var radius_x = 280.0 * spread
    var radius_y = 360.0 * spread
    return Vector2(
        rng.randf_range(center.x - radius_x, center.x + radius_x),
        rng.randf_range(center.y - radius_y, center.y + radius_y)
    )

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
    if not partridge_visible:
        status_text = "الوقت ليلي — عُد في وقت نشاط الحجل"
        queue_redraw()
        return
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

func _process(delta):
    weather_refresh_timer += delta
    if weather_refresh_timer >= weather_refresh_seconds:
        weather_refresh_timer = 0.0
        _request_live_weather()
    if not live_weather_enabled or weather_updated_at.is_empty():
        _update_world_conditions()
    _update_partridge_behavior()
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

    # Full-screen mobile location picker.
    if location_menu_open:
        if p.x >= 600 and p.y < 100:
            location_menu_open = false
            queue_redraw()
            return
        if p.y >= 125 and p.y < 965:
            var options = _location_options()
            var index = int((p.y - 125) / 60.0)
            if index >= 0 and index < options.size():
                var chosen = str(options[index])
                if location_level == 0:
                    select_governorate(chosen)
                    location_level = 1
                elif location_level == 1:
                    select_area(chosen)
                    location_level = 2
                else:
                    select_village(chosen)
                    location_menu_open = false
                queue_redraw()
            return
        if p.y >= 1000 and p.y < 1080:
            if location_level > 0:
                location_level -= 1
                queue_redraw()
            return
        return

    # Hunting location selectors: governorate, area, village.
    if p.y >= 610 and p.y < 638:
        _open_location_menu(0)
        return
    if p.y >= 638 and p.y < 665:
        _open_location_menu(1)
        return
    if p.y >= 665 and p.y < 690:
        _open_location_menu(2)
        return

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
    if location_menu_open:
        draw_rect(Rect2(0, 0, 720, 1280), Color("#10251a"))
        draw_rect(Rect2(20, 20, 680, 80), Color("#315d39"))
        draw_string(ThemeDB.fallback_font, Vector2(40, 70), _location_title(), HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(635, 70), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, 35, Color("#ffe08a"))
        var options = _location_options()
        for i in range(options.size()):
            if i >= 14:
                break
            var yy = 125 + i * 60
            draw_rect(Rect2(25, yy, 670, 58), Color("#294f32"))
            draw_string(ThemeDB.fallback_font, Vector2(45, yy + 38), str(options[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(35, 1040), "رجوع", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#d9f99d"))
        draw_string(ThemeDB.fallback_font, Vector2(35, 1085), "المحافظة ← المنطقة ← القرية", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#fff0a8"))
        return

    draw_rect(Rect2(0, 0, 720, 1280), Color("#76ad5d"))
    draw_rect(Rect2(0, 0, 720, 175), Color("#79b7d9"))
    draw_rect(Rect2(0, 0, 720, 110), Color("#173f2b"))

    draw_string(ThemeDB.fallback_font, Vector2(25, 45), "PARTRIDGE HUNTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(25, 85), "صيد الحجل - Multiplayer", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d9f99d"))
    draw_string(ThemeDB.fallback_font, Vector2(500, 45), "النقاط: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(500, 80), "الطلقات: " + str(ammo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffe08a"))
    var accuracy := 0.0 if shots_fired == 0 else (float(hits) / float(shots_fired)) * 100.0
    draw_string(ThemeDB.fallback_font, Vector2(25, 575), "الدقة: %d%%   السلسلة: %d   أفضل سلسلة: %d" % [roundi(accuracy), streak, best_streak], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#fff0a8"))
    draw_rect(Rect2(20, 610, 680, 78), Color("#315d39"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 630), "المحافظة: " + selected_governorate + "   (اضغط للتغيير)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(35, 655), "المنطقة: " + selected_area + "   (اضغط للتغيير)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(35, 680), "القرية: " + selected_village + "   (اضغط للتغيير)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(25, 715), "الوقت والطقس: " + _hunting_condition_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fff0a8"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 740), "تأثير الظروف على الصيد: %.2fx" % _world_difficulty(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#d9f99d"))

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
    if partridge_visible:
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
