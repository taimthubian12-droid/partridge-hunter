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
var prey_species := "الحجل"
var prey_radius := 48.0
var prey_reward_multiplier := 1.0
var prey_revealed := true
var track_progress := 0.0
var track_type := "آثار أقدام"
var track_quality := 0.75
var track_direction := Vector2.RIGHT
var track_clues_found := 0
var prey_danger_level := 0
const PREY_TYPES := ["الحجل", "الأرنب البري", "السمان", "الحمام البري", "الدراج", "الذئب", "الضبع"]
var partridge_velocity := Vector2(0.0, 0.0)
var mission_target := 5
var mission_progress := 0
var mission_reward := 100
var mission_level := 1
var dog_search_progress := 0.0
var dog_search_duration := 3.0
var dog_level := 1
var dog_xp := 0
var dog_xp_next := 100
var dog_upgrade_points := 0
var dog_stats := {"speed": 1.0, "scent": 1.0, "accuracy": 0.70, "stamina": 1.0}
var dog_upgrade_open := false
var kennel_open := false
var dog_coins := 1200
var owned_dogs := [true, false, false, false, false]
var dog_profiles := []
var dog_unlock_costs := [0, 400, 700, 1000, 1500]
var kennel_shop_open := false
var shop_items := [{"name":"طوق تدريب","cost":120,"bonus":"stamina"},{"name":"صافرة صيد","cost":180,"bonus":"speed"},{"name":"حقيبة مكافآت","cost":220,"bonus":"accuracy"},{"name":"رائحة تدريب","cost":260,"bonus":"scent"}]
var owned_items := [false, false, false, false]
var equipped_items := [false, false, false, false]
var daily_reward_claimed_date := ""
var daily_reward_amount := 250
var reward_chest_count := 0
var total_coins_earned := 0
var last_hunt_reward := 0
var daily_missions_date := ""
var daily_missions_claimed := [false, false, false]
var daily_mission_progress := [0, 0, 0]
var weekly_missions_week := ""
var weekly_mission_progress := 0
var weekly_mission_claimed := false
var hunter_level := 1
var hunter_xp := 0
var hunter_xp_next := 100
var total_hunts := 0
var total_hits := 0
var best_streak := 0
var hunter_rank := "مبتدئ"
var hunter_profile_open := false
var hunter_achievements := [false, false, false, false]
var start_menu_open := true
var hunting_mode := 0
var hunting_mode_names := ["صيد حر", "مهمة", "تحدي السلسلة"]
var hunting_mode_multiplier := 1.0
var challenge_ammo := 0
var terrain_type := "سهول"
var dog_variant := 1
var dog_variant_names := ["بونتر أبيض وبني", "بونتر أسود وأبيض", "بونتر بني", "بونتر سريع", "بونتر مرقّط"]
const DOG_STATS := [
    {"speed": 1.00, "scent": 1.00, "accuracy": 0.70},
    {"speed": 1.05, "scent": 1.15, "accuracy": 0.74},
    {"speed": 1.12, "scent": 1.05, "accuracy": 0.76},
    {"speed": 1.30, "scent": 0.95, "accuracy": 0.72},
    {"speed": 1.08, "scent": 1.30, "accuracy": 0.82},
]
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
var hunt_feedback := ""
var hunt_feedback_timer := 0.0
var hunt_feedback_success := false
var round_shots := 0
var host_ip := "192.168.1.2"
var players: Dictionary = {}
var editing_name := false
var location_menu_open := false
var location_level := 0

func _ready():
    _init_dog_profiles()
    _load_dog_profiles()
    _apply_mission_level()
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
    start_menu_open = true
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

func _terrain_for_area() -> String:
    var key = selected_governorate + "|" + selected_area
    if key.contains("القلمون") or key.contains("تدمر") or key.contains("جبل العرب"):
        return "جبال وهضاب"
    if key.contains("الغاب") or key.contains("الحفة") or key.contains("جسر الشغور"):
        return "غابات وأودية"
    if key.contains("الميادين") or key.contains("البوكمال") or key.contains("الطبقة"):
        return "سهول نهرية"
    return "سهول"

func _apply_mission_level():
    mission_target = 4 + mission_level
    mission_reward = 100 + mission_level * 50
    dog_search_duration = maxf(1.5, 3.5 - mission_level * 0.15)
    terrain_type = _terrain_for_area()

func _init_dog_profiles():
    dog_profiles.clear()
    for i in range(DOG_STATS.size()):
        dog_profiles.append({"level": 1, "xp": 0, "xp_next": 100, "points": 0, "stats": DOG_STATS[i].duplicate()})

func _active_profile() -> Dictionary:
    if dog_profiles.size() == 0:
        _init_dog_profiles()
    return dog_profiles[dog_variant - 1]

func _sync_active_profile():
    var p = _active_profile()
    dog_level = int(p["level"])
    dog_xp = int(p["xp"])
    dog_xp_next = int(p["xp_next"])
    dog_upgrade_points = int(p["points"])
    dog_stats = p["stats"].duplicate()

func _store_active_profile():
    var p = _active_profile()
    p["level"] = dog_level
    p["xp"] = dog_xp
    p["xp_next"] = dog_xp_next
    p["points"] = dog_upgrade_points
    p["stats"] = dog_stats.duplicate()
    dog_profiles[dog_variant - 1] = p

func _save_dog_profiles():
    _store_active_profile()
    var cfg = ConfigFile.new()
    cfg.set_value("kennel", "owned", owned_dogs)
    cfg.set_value("kennel", "coins", dog_coins)
    cfg.set_value("kennel", "profiles", dog_profiles)
    cfg.set_value("kennel", "active", dog_variant)
    cfg.set_value("shop", "owned_items", owned_items)
    cfg.set_value("shop", "equipped_items", equipped_items)
    cfg.set_value("rewards", "daily_claimed_date", daily_reward_claimed_date)
    cfg.set_value("rewards", "chests", reward_chest_count)
    cfg.set_value("rewards", "total_earned", total_coins_earned)
    cfg.set_value("missions", "daily_date", daily_missions_date)
    cfg.set_value("missions", "daily_claimed", daily_missions_claimed)
    cfg.set_value("missions", "daily_progress", daily_mission_progress)
    cfg.set_value("missions", "weekly_week", weekly_missions_week)
    cfg.set_value("missions", "weekly_progress", weekly_mission_progress)
    cfg.set_value("missions", "weekly_claimed", weekly_mission_claimed)
    cfg.set_value("hunter", "level", hunter_level)
    cfg.set_value("hunter", "xp", hunter_xp)
    cfg.set_value("hunter", "total_hunts", total_hunts)
    cfg.set_value("hunter", "total_hits", total_hits)
    cfg.set_value("hunter", "best_streak", best_streak)
    cfg.set_value("hunter", "rank", hunter_rank)
    cfg.set_value("hunter", "achievements", hunter_achievements)
    cfg.save("user://kennel.cfg")

func _load_dog_profiles():
    var cfg = ConfigFile.new()
    if cfg.load("user://kennel.cfg") != OK:
        _sync_active_profile()
        return
    owned_dogs = cfg.get_value("kennel", "owned", owned_dogs)
    dog_coins = int(cfg.get_value("kennel", "coins", dog_coins))
    var saved = cfg.get_value("kennel", "profiles", dog_profiles)
    if saved is Array and saved.size() == DOG_STATS.size():
        dog_profiles = saved
    dog_variant = clampi(int(cfg.get_value("kennel", "active", dog_variant)), 1, DOG_STATS.size())
    owned_items = cfg.get_value("shop", "owned_items", owned_items)
    equipped_items = cfg.get_value("shop", "equipped_items", equipped_items)
    if not (equipped_items is Array) or equipped_items.size() != shop_items.size():
        equipped_items = [false, false, false, false]
    daily_reward_claimed_date = str(cfg.get_value("rewards", "daily_claimed_date", daily_reward_claimed_date))
    reward_chest_count = maxi(0, int(cfg.get_value("rewards", "chests", reward_chest_count)))
    total_coins_earned = maxi(0, int(cfg.get_value("rewards", "total_earned", total_coins_earned)))
    daily_missions_date = str(cfg.get_value("missions", "daily_date", ""))
    daily_missions_claimed = cfg.get_value("missions", "daily_claimed", daily_missions_claimed)
    daily_mission_progress = cfg.get_value("missions", "daily_progress", daily_mission_progress)
    weekly_missions_week = str(cfg.get_value("missions", "weekly_week", ""))
    weekly_mission_progress = int(cfg.get_value("missions", "weekly_progress", 0))
    weekly_mission_claimed = bool(cfg.get_value("missions", "weekly_claimed", false))
    hunter_level = maxi(1, int(cfg.get_value("hunter", "level", 1)))
    hunter_xp = maxi(0, int(cfg.get_value("hunter", "xp", 0)))
    hunter_xp_next = 100 + (hunter_level - 1) * 50
    total_hunts = maxi(0, int(cfg.get_value("hunter", "total_hunts", 0)))
    total_hits = maxi(0, int(cfg.get_value("hunter", "total_hits", 0)))
    best_streak = maxi(0, int(cfg.get_value("hunter", "best_streak", 0)))
    hunter_rank = str(cfg.get_value("hunter", "rank", "مبتدئ"))
    hunter_achievements = cfg.get_value("hunter", "achievements", hunter_achievements)
    if hunter_achievements.size() != 4: hunter_achievements = [false, false, false, false]
    _refresh_missions()
    _sync_active_profile()

func _buy_or_select_dog(index: int):
    if index < 0 or index >= owned_dogs.size():
        return
    if owned_dogs[index]:
        dog_variant = index + 1
        _sync_active_profile()
        kennel_open = false
        status_text = "تم اختيار %s" % dog_variant_names[index]
        _save_dog_profiles()
        queue_redraw()
        return
    var cost = dog_unlock_costs[index]
    if dog_coins >= cost:
        dog_coins -= cost
        owned_dogs[index] = true
        dog_variant = index + 1
        _sync_active_profile()
        kennel_open = false
        status_text = "تم فتح %s مقابل %d عملة" % [dog_variant_names[index], cost]
        _save_dog_profiles()
    else:
        status_text = "تحتاج إلى %d عملة لفتح هذا الكلب" % cost
    queue_redraw()

func _apply_equipped_item_bonus(index: int, enabled: bool):
    if index < 0 or index >= shop_items.size():
        return
    var stat = str(shop_items[index]["bonus"])
    if not dog_stats.has(stat):
        return
    var amount = (0.10 if stat != "accuracy" else 0.05)
    dog_stats[stat] = float(dog_stats[stat]) + (amount if enabled else -amount)

func _buy_shop_item(index: int):
    if index < 0 or index >= shop_items.size():
        return
    if owned_items[index]:
        _toggle_shop_item(index)
        return
    var item = shop_items[index]
    var cost = int(item["cost"])
    if dog_coins < cost:
        status_text = "رصيدك غير كافٍ"
        return
    dog_coins -= cost
    owned_items[index] = true
    equipped_items[index] = true
    _apply_equipped_item_bonus(index, true)
    _save_dog_profiles()
    status_text = "تم شراء وتجهيز %s" % item["name"]
    queue_redraw()

func _toggle_shop_item(index: int):
    if index < 0 or index >= shop_items.size() or not owned_items[index]:
        return
    equipped_items[index] = not equipped_items[index]
    _apply_equipped_item_bonus(index, equipped_items[index])
    _save_dog_profiles()
    status_text = ("%s: %s" % [shop_items[index]["name"], "تم التجهيز" if equipped_items[index] else "تم إلغاء التجهيز"])
    queue_redraw()


func _today_key() -> String:
    var d = Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func _hunter_rank_for_level(level: int) -> String:
    if level >= 20: return "أسطورة الحجل"
    if level >= 15: return "صياد محترف"
    if level >= 10: return "صياد خبير"
    if level >= 6: return "صياد متقدم"
    if level >= 3: return "صياد"
    return "مبتدئ"

func _add_hunter_xp(amount: int):
    hunter_xp += maxi(0, amount)
    while hunter_xp >= hunter_xp_next:
        hunter_xp -= hunter_xp_next
        hunter_level += 1
        hunter_xp_next = 100 + (hunter_level - 1) * 50
        var level_reward = 150 + hunter_level * 25
        dog_coins += level_reward
        total_coins_earned += level_reward
        status_text = "🏅 ترقية! رتبة %s | +%d عملة" % [_hunter_rank_for_level(hunter_level), level_reward]
    hunter_rank = _hunter_rank_for_level(hunter_level)

func _check_hunter_achievements():
    var targets = [1, 10, 50, 0]
    var unlocked = [total_hits >= 1, total_hits >= 10, total_hits >= 50, hunter_level >= 10]
    var rewards = [50, 150, 400, 1000]
    for i in range(4):
        if unlocked[i] and not hunter_achievements[i]:
            hunter_achievements[i] = true
            dog_coins += rewards[i]
            total_coins_earned += rewards[i]
            status_text = "إنجاز جديد! +%d عملة" % rewards[i]
    _save_dog_profiles()

func _record_hunt_stats(hit: bool):
    total_hunts += 1
    if hit:
        total_hits += 1
        best_streak = maxi(best_streak, streak)
        _add_hunter_xp(20 + mission_level * 5)
        _check_hunter_achievements()
    else:
        _add_hunter_xp(5)
    _save_dog_profiles()

func _set_hunting_mode(mode: int):
    hunting_mode = clampi(mode, 0, 2)
    if hunting_mode == 0:
        hunting_mode_multiplier = 1.0
        status_text = "نمط الصيد الحر جاهز"
    elif hunting_mode == 1:
        hunting_mode_multiplier = 1.25
        status_text = "نمط المهمة جاهز — مكافآت أعلى"
    else:
        hunting_mode_multiplier = 1.60
        challenge_ammo = 5
        ammo = challenge_ammo
        streak = 0
        status_text = "تحدي السلسلة: 5 طلقات — حافظ على السلسلة"
    start_menu_open = false
    target = _new_target()
    partridge_visible = true
    dog_has_found_prey = false
    queue_redraw()

func _open_start_menu():
    start_menu_open = true
    hunter_profile_open = false
    location_menu_open = false
    kennel_open = false
    kennel_shop_open = false
    dog_upgrade_open = false
    queue_redraw()

func _hunt_coin_reward() -> int:
    var accuracy := 0.0 if shots_fired == 0 else float(hits) / float(shots_fired)
    var base := roundi((12 + mission_level * 3) * prey_reward_multiplier)
    var streak_bonus := mini(streak * 2, 30)
    var accuracy_bonus := roundi(accuracy * 15.0)
    var condition_bonus := maxi(0, 8 - roundi((_world_difficulty() - 1.0) * 8.0))
    return maxi(5, roundi((base + streak_bonus + accuracy_bonus + condition_bonus) * hunting_mode_multiplier))

func _grant_hunt_reward()
        _update_activity_missions():
    last_hunt_reward = _hunt_coin_reward()
    dog_coins += last_hunt_reward
    total_coins_earned += last_hunt_reward
    if streak > 0 and streak % 5 == 0:
        reward_chest_count += 1
        status_text = "🎁 صندوق مكافأة جديد! +%d عملة" % last_hunt_reward
    else:
        status_text = "إصابة ناجحة: +%d عملة" % last_hunt_reward
    _save_dog_profiles()

func _open_reward_chest():
    if reward_chest_count <= 0:
        status_text = "لا يوجد صندوق مكافأة متاح"
        return
    reward_chest_count -= 1
    var chest_reward = rng.randi_range(80, 220) + mission_level * 15
    dog_coins += chest_reward
    total_coins_earned += chest_reward
    status_text = "🎁 فتحت الصندوق وحصلت على +%d عملة" % chest_reward
    _save_dog_profiles()
    queue_redraw()

func _mission_day_key() -> String:
    return Time.get_date_string_from_system()

func _mission_week_key() -> String:
    var d = Time.get_date_dict_from_system()
    return "%04d-W%02d" % [int(d.year), int((int(d.day_of_year) - 1) / 7) + 1]

func _refresh_missions():
    var day = _mission_day_key()
    if daily_missions_date != day:
        daily_missions_date = day
        daily_missions_claimed = [false, false, false]
        daily_mission_progress = [0, 0, 0]
    var week = _mission_week_key()
    if weekly_missions_week != week:
        weekly_missions_week = week
        weekly_mission_progress = 0
        weekly_mission_claimed = false

func _update_activity_missions():
    _refresh_missions()
    daily_mission_progress[0] = mini(5, daily_mission_progress[0] + 1)
    daily_mission_progress[1] = mini(10, daily_mission_progress[1] + 1)
    if streak >= 3:
        daily_mission_progress[2] = mini(3, daily_mission_progress[2] + 1)
    weekly_mission_progress = mini(25, weekly_mission_progress + 1)

func _claim_activity_mission(index: int):
    _refresh_missions()
    var targets = [5, 10, 3]
    var rewards = [80, 160, 260]
    if index < 0 or index >= targets.size() or daily_missions_claimed[index]:
        return
    if daily_mission_progress[index] < targets[index]:
        status_text = "المهمة اليومية لم تكتمل بعد"
        return
    daily_missions_claimed[index] = true
    dog_coins += rewards[index]
    total_coins_earned += rewards[index]
    status_text = "🎯 مكافأة المهمة اليومية: +%d عملة" % rewards[index]
    _save_dog_profiles()

func _claim_weekly_mission():
    _refresh_missions()
    if weekly_mission_claimed:
        status_text = "المكافأة الأسبوعية مستلمة"
        return
    if weekly_mission_progress < 25:
        status_text = "أكمل 25 عملية صيد هذا الأسبوع"
        return
    weekly_mission_claimed = true
    var reward = 900 + mission_level * 50
    dog_coins += reward
    total_coins_earned += reward
    status_text = "🏆 مكافأة الأسبوع: +%d عملة" % reward
    _save_dog_profiles()

func _claim_daily_reward():
    var today = _today_key()
    if daily_reward_claimed_date == today:
        status_text = "تم استلام مكافأة اليوم مسبقاً"
        return
    dog_coins += daily_reward_amount
    daily_reward_claimed_date = today
    _save_dog_profiles()
    status_text = "🎁 استلمت المكافأة اليومية: +%d عملة" % daily_reward_amount
    queue_redraw()

func _open_shop():
    kennel_shop_open = true
    kennel_open = false
    dog_upgrade_open = false
    queue_redraw()

func _open_kennel():
    kennel_open = true
    dog_upgrade_open = false
    queue_redraw()

func _dog_stat(name: String) -> float:
    if dog_stats.has(name):
        return float(dog_stats[name])
    return float(DOG_STATS[dog_variant - 1].get(name, 1.0))

func _add_dog_xp(amount: int):
    dog_xp += amount
    while dog_xp >= dog_xp_next:
        dog_xp -= dog_xp_next
        dog_level += 1
        dog_upgrade_points += 2
        dog_xp_next = 100 + (dog_level - 1) * 50
        status_text = "🐕 ارتفع مستوى الكلب إلى %d! حصلت على نقطتي تطوير" % dog_level

func _upgrade_dog(stat_name: String):
    if dog_upgrade_points <= 0:
        status_text = "لا توجد نقاط تطوير"
        return
    if not dog_stats.has(stat_name):
        return
    dog_upgrade_points -= 1
    dog_stats[stat_name] = float(dog_stats[stat_name]) + (0.05 if stat_name != "accuracy" else 0.03)
    status_text = "تم تطوير %s" % stat_name
    queue_redraw()

func _draw_track_clues():
    if prey_revealed:
        return
    var visible_clues = mini(track_clues_found, 4)
    for i in range(visible_clues):
        var distance = 75.0 + float(i) * 55.0
        var wobble = sin(float(i) * 2.1) * 24.0
        var pos = target - track_direction * distance + track_direction.rotated(PI / 2.0) * wobble
        if prey_species in ["الأرنب البري", "الذئب", "الضبع"]:
            draw_circle(pos, 8.0, Color("#c9b08a"))
            draw_circle(pos + track_direction.rotated(PI / 2.0) * 9.0, 5.0, Color("#8b7355"))
        else:
            draw_line(pos - track_direction * 10.0, pos + track_direction * 10.0, Color("#e5d9a6"), 4.0)
            draw_circle(pos, 3.0, Color("#fff4b8"))
    if track_clues_found > 0:
        var arrow_start = target - track_direction * 25.0
        var arrow_end = arrow_start + track_direction * 65.0
        draw_line(arrow_start, arrow_end, Color("#d9f99d"), 5.0)

func _inspect_track():
    if prey_revealed:
        status_text = "الطريدة مكشوفة بالفعل"
        return
    var chance = clampf(track_quality + _dog_stat("scent") * 0.08, 0.15, 0.98)
    if rng.randf() <= chance:
        track_clues_found += 1
        track_quality = clampf(track_quality + 0.08, 0.25, 1.0)
        status_text = "وجدت أثراً — اتبع المسار"
    else:
        status_text = "الأثر ضعيف — جرّب البحث مرة أخرى"
    queue_redraw()

func _start_dog_search():
    if dog_searching:

        return
    dog_searching = true
    dog_search_progress = 0.0
    dog_has_found_prey = false
    prey_revealed = false
    track_progress = 0.0
    status_text = "%s بدأ تتبع الأثر..." % dog_variant_names[dog_variant - 1]
    queue_redraw()

func _update_dog_search(delta):
    if not dog_searching:
        return
    dog_search_progress += delta * _dog_stat("speed") * _dog_stat("scent")
    track_progress = clampf(dog_search_progress / maxf(0.5, dog_search_duration), 0.0, 1.0)
    var required = dog_search_duration / maxf(0.55, _dog_stat("scent"))
    if dog_search_progress >= required:
        dog_searching = false
        var roll = rng.randf()
        if roll <= clampf(_dog_stat("accuracy") + track_clues_found * 0.04, 0.0, 0.99):
            dog_has_found_prey = true
            prey_revealed = true
            _add_dog_xp(35)
            status_text = "🐕 كشف أثر %s — الطريدة ظهرت!" % prey_species
            target += Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-15.0, 15.0))
        else:
            status_text = "لم يكتمل التتبع — ابحث عن الأثر أو أعد إرسال الكلب"
        queue_redraw()

func _advance_mission():
    mission_level += 1
    mission_progress = 0
    _apply_mission_level()
    status_text = "المرحلة %d بدأت — %s" % [mission_level, terrain_type]

func _choose_prey():
    var pool = PREY_TYPES.duplicate()
    if terrain_type == "غابات وأودية":
        pool = ["الدراج", "الحمام البري", "الأرنب البري", "الحجل"]
    elif terrain_type == "سهول نهرية":
        pool = ["السمان", "الحمام البري", "الأرنب البري", "الحجل"]
    elif terrain_type == "جبال وهضاب":
        pool = ["الحجل", "الأرنب البري", "السمان"]
    prey_species = pool[rng.randi_range(0, pool.size() - 1)]
    prey_danger_level = 2 if prey_species == "الذئب" else (3 if prey_species == "الضبع" else 0)
    prey_revealed = prey_danger_level == 0
    track_type = "آثار أقدام" if prey_species in ["الأرنب البري", "الذئب", "الضبع"] else "ريش وآثار حركة"
    track_quality = clampf(0.9 - wind_speed / 25.0 - (0.15 if weather == "ضباب" else 0.0), 0.25, 0.95)
    track_direction = Vector2.from_angle(rng.randf_range(-PI, PI))
    track_clues_found = 0
    prey_radius = {"الحجل":48.0,"الأرنب البري":42.0,"السمان":34.0,"الحمام البري":30.0,"الدراج":52.0,"الذئب":58.0,"الضبع":62.0}.get(prey_species, 44.0)
    prey_reward_multiplier = {"الحجل":1.0,"الأرنب البري":1.15,"السمان":1.25,"الحمام البري":1.35,"الدراج":1.60,"الذئب":2.10,"الضبع":2.40}.get(prey_species, 1.0)

func _update_partridge_behavior():
    partridge_visible = daylight
    partridge_speed = 1.0
    partridge_speed *= {"الحجل":1.0,"الأرنب البري":1.15,"السمان":1.25,"الحمام البري":1.40,"الدراج":0.90}.get(prey_species, 1.0)
    if game_hour < 7.0 or game_hour >= 17.0:
        partridge_speed += 0.20
    if weather == "ضباب" or weather == "رذاذ/مطر" or weather == "زخات مطر":
        partridge_speed -= 0.10
    if wind_speed >= 7.0:
        partridge_speed += 0.15
    if hunting_mode == 1:
        partridge_speed += 0.10
    elif hunting_mode == 2:
        partridge_speed += 0.25
    partridge_speed = clampf(partridge_speed, 0.75, 1.75)
    var phase = Time.get_ticks_msec() / 1000.0
    partridge_velocity = Vector2(cos(phase * partridge_speed * 1.7), sin(phase * partridge_speed * 1.2)) * (28.0 * partridge_speed)

func _hunting_condition_text() -> String:
    var period = "فجر" if game_hour < 7.0 else ("صباح" if game_hour < 12.0 else ("بعد الظهر" if game_hour < 17.0 else ("غروب" if game_hour < 20.0 else "ليل")))
    var live = "مباشر" if live_weather_enabled and weather_updated_at != "" else "محلي"
    return "%s | %s | %s°C | رياح %.1f م/ث | %s" % [period, weather, temperature, wind_speed, live]

func _new_target() -> Vector2:
    _choose_prey()
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

func _show_hunt_feedback(message: String, success: bool):
    hunt_feedback = message
    hunt_feedback_success = success
    hunt_feedback_timer = 1.2
    queue_redraw()

func _fire_at(point: Vector2):
    if not partridge_visible:
        status_text = "الوقت ليلي — عُد في وقت نشاط الحجل"
        queue_redraw()
        return
    if not prey_revealed:
        status_text = "لا تطلق الآن — اتبع الأثر أو أرسل كلب الصيد لكشف الطريدة"
        queue_redraw()
        return
    if hunting_mode == 2 and challenge_ammo <= 0:
        queue_redraw()
        return
    if ammo <= 0:
        ammo = 8
        status_text = "تمت إعادة تعبئة الخرطوش"
        queue_redraw()
        return
    ammo -= 1
    round_shots += 1
    if hunting_mode == 2:
        challenge_ammo = maxi(0, challenge_ammo - 1)
    if point.distance_to(target) < prey_radius * 1.55:
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
        mission_progress += 1
        _grant_hunt_reward()
        _record_hunt_stats(true)
        if mission_progress >= mission_target:
            score += mission_reward
            dog_coins += int(mission_reward / 10)
            status_text = "اكتملت المرحلة! +%d نقطة و+%d عملة" % [mission_reward, int(mission_reward / 10)]
            _save_dog_profiles()
            _advance_mission()
        target = _new_target()
        dog_has_found_prey = false
        status_text = "إصابة! أطلق النار على الطريدة التالية"
        _show_hunt_feedback("🎯 إصابة! +%d عملة" % last_hunt_reward, true)
        _sync_local_player()
    else:
        shots_fired += 1
        streak = 0
        status_text = "لم تصب الهدف — بدأت سلسلة جديدة"
        _show_hunt_feedback("💨 لم تصب — حاول مرة أخرى", false)
    queue_redraw()

func _process(delta):
    if hunt_feedback_timer > 0.0:
        hunt_feedback_timer = maxf(0.0, hunt_feedback_timer - delta)
        if hunt_feedback_timer == 0.0:
            hunt_feedback = ""
    _update_dog_search(delta)
    weather_refresh_timer += delta
    if weather_refresh_timer >= weather_refresh_seconds:
        weather_refresh_timer = 0.0
        _request_live_weather()
    if not live_weather_enabled or weather_updated_at.is_empty():
        _update_world_conditions()
    _update_partridge_behavior()
    if partridge_visible and not location_menu_open:
        target += partridge_velocity * delta
        target.x = clampf(target.x, 55.0, 665.0)
        target.y = clampf(target.y, 285.0, 600.0)
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

    if start_menu_open:
        if p.x >= 45 and p.x < 240 and p.y >= 465 and p.y < 520:
            _open_location_menu(0)
            return
        if p.x >= 260 and p.x < 455 and p.y >= 465 and p.y < 520:
            hunter_profile_open = true
            start_menu_open = false
            queue_redraw()
            return
        if p.y >= 640 and p.y < 715:
            _set_hunting_mode(0)
            return
        if p.y >= 730 and p.y < 805:
            _set_hunting_mode(1)
            return
        if p.y >= 820 and p.y < 895:
            _set_hunting_mode(2)
            return
        return

    if start_menu_open:
        draw_rect(Rect2(0, 0, 720, 1280), Color("#0b1d14"))
        draw_rect(Rect2(20, 25, 680, 500), Color("#173f2b"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 85), "رحلة صيد", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(45, 125), "استكشاف وتتبع الطرائد", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#d9f99d"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 175), "ابدأ جولتك واختر طريقة اللعب", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#fff0a8"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 225), "🏅 %s — المستوى %d" % [hunter_rank, hunter_level], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#bfdbfe"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 265), "🪙 %d عملة   |   🐕 %s" % [dog_coins, dog_variant_names[dog_variant - 1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fde68a"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 305), "📍 %s / %s / %s" % [selected_governorate, selected_area, selected_village], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(45, 340), "🌤 %s  %.1f°C  |  تضاريس: %s" % [weather, temperature, terrain_type], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#c7f9cc"))
        draw_rect(Rect2(45, 385, 610, 18), Color("#294f32"))
        draw_rect(Rect2(45, 385, 610 * clampf(float(hunter_xp) / float(maxi(1, hunter_xp_next)), 0.0, 1.0), 18), Color("#d9f99d"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 435), "تقدم المستوى: %d / %d XP" % [hunter_xp, hunter_xp_next], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_rect(Rect2(45, 465, 195, 48), Color("#315d39"))
        draw_rect(Rect2(260, 465, 195, 48), Color("#315d39"))
        draw_rect(Rect2(475, 465, 180, 48), Color("#315d39"))
        draw_string(ThemeDB.fallback_font, Vector2(65, 497), "📍 تغيير الموقع", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(280, 497), "🏅 ملف الصياد", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(495, 497), "نمط: " + hunting_mode_names[hunting_mode], HORIZONTAL_ALIGNMENT_LEFT, 160, 14, Color("#fde68a"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 615), "اختر نمط الصيد", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
        draw_rect(Rect2(45, 640, 610, 75), Color("#294f32"))
        draw_rect(Rect2(45, 730, 610, 75), Color("#315d39"))
        draw_rect(Rect2(45, 820, 610, 75), Color("#3f3b22"))
        draw_rect(Rect2(45, 910, 610, 75), Color("#5a3820"))
        draw_string(ThemeDB.fallback_font, Vector2(70, 687), "🎯 صيد حر — جولة عادية ومكافآت متوازنة", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(70, 777), "📋 مهمة — مكافآت الصيد ×1.25", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(70, 867), "🔥 تحدي السلسلة — 5 طلقات ومكافآت ×1.60", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fff0a8"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 1035), "الحالة: " + status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#dbeafe"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 1080), "اضغط على أحد الأنماط لبدء الصيد", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d9f99d"))
        return

    if hunter_profile_open:
        if p.y < 120:
            hunter_profile_open = false
            queue_redraw()
        return

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

    if p.y >= 540 and p.y < 605:
        hunter_profile_open = true
        queue_redraw()
        return

    # Hunting location selectors: governorate, area, village.
    if p.x >= 520 and p.x <= 700 and p.y >= 805 and p.y <= 900:
    dog_variant += 1
    if dog_variant > dog_variant_names.size():
        dog_variant = 1
    status_text = "تم اختيار %s" % dog_variant_names[dog_variant - 1]
    queue_redraw()
    return

if kennel_shop_open:
    if p.x >= 20 and p.x <= 700 and p.y >= 335 and p.y < 760:
        var shop_index = int((p.y - 335) / 95.0)
        if shop_index >= 0 and shop_index < shop_items.size():
            _buy_shop_item(shop_index)
        return
    if p.y >= 760:
        kennel_shop_open = false
        queue_redraw()
    return

if kennel_open:
    if p.x >= 20 and p.x <= 700 and p.y >= 320 and p.y < 770:
        var idx = int((p.y - 320) / 82.0)
        if idx >= 0 and idx < 5:
            _buy_or_select_dog(idx)
        return
    if p.y >= 770:
        kennel_open = false
        queue_redraw()
    return

if p.y >= 920 and p.y < 980:
    _open_shop()
    return
if p.y >= 980 and p.y < 1040:
    _open_kennel()
    return
if p.y >= 1040 and p.y < 1090:
    _claim_daily_reward()
    return
if p.y >= 1090 and p.y < 1140:
    _open_reward_chest()
    return
if p.y >= 1140 and p.y < 1190:
    _claim_activity_mission(0 if p.x < 240 else (1 if p.x < 480 else 2))
    return
if p.y >= 1190 and p.y < 1240:
    _claim_weekly_mission()
    return

if p.y >= 805 and p.y < 850 and p.x < 250:
    _inspect_track()
    return
if p.y >= 805 and p.y < 850 and p.x < 500:
    _start_dog_search()
    return
if p.y >= 850 and p.y < 910 and p.x < 500:
    dog_upgrade_open = not dog_upgrade_open
    queue_redraw()
    return
if dog_upgrade_open and p.y >= 910:
    var col = int(p.x / 180.0)
    if col == 0:
        _upgrade_dog("scent")
    elif col == 1:
        _upgrade_dog("speed")
    elif col == 2:
        _upgrade_dog("accuracy")
    else:
        _upgrade_dog("stamina")
    return

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

func _map_position_for_area() -> Vector2:
    var coords = AREA_COORDINATES.get(selected_governorate + "|" + selected_area, Vector2(35.0, 37.0))
    var min_lat = 32.0
    var max_lat = 38.0
    var min_lon = 35.0
    var max_lon = 43.0
    var x = 485.0 + ((coords.y - min_lon) / (max_lon - min_lon)) * 195.0
    var y = 875.0 - ((coords.x - min_lat) / (max_lat - min_lat)) * 100.0
    return Vector2(clampf(x, 490.0, 680.0), clampf(y, 775.0, 875.0))

func _draw():
    _draw_track_clues()
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

    if hunter_profile_open:
        draw_rect(Rect2(0, 0, 720, 1280), Color("#10251a"))
        draw_rect(Rect2(25, 25, 670, 700), Color("#173f2b"))
        draw_string(ThemeDB.fallback_font, Vector2(50, 75), "ملف الصياد", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(50, 125), "الاسم: %s" % hunter_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#d9f99d"))
        draw_string(ThemeDB.fallback_font, Vector2(50, 170), "الرتبة: %s | المستوى: %d" % [hunter_rank, hunter_level], HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#fde68a"))
        draw_string(ThemeDB.fallback_font, Vector2(50, 215), "XP: %d / %d" % [hunter_xp, hunter_xp_next], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#bfdbfe"))
        draw_string(ThemeDB.fallback_font, Vector2(50, 260), "إجمالي الصيد: %d" % total_hunts, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(50, 300), "الإصابات: %d | أفضل سلسلة: %d" % [total_hits, best_streak], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(50, 340), "العملات المكتسبة: %d" % total_coins_earned, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#c7f9cc"))
        draw_string(ThemeDB.fallback_font, Vector2(50, 390), "الإنجازات", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#ffe08a"))
        var names = ["أول إصابة", "10 إصابات", "50 إصابة", "المستوى 10"]
        for i in range(4):
            var state = "مكتمل" if hunter_achievements[i] else "مغلق"
            draw_string(ThemeDB.fallback_font, Vector2(55, 430 + i * 45), "%s: %s" % [names[i], state], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fef3c7"))
        draw_string(ThemeDB.fallback_font, Vector2(50, 660), "اضغط أعلى الشاشة للعودة", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#dbeafe"))
        return

    draw_rect(Rect2(0, 0, 720, 1280), Color("#76ad5d"))
    draw_rect(Rect2(0, 0, 720, 175), Color("#79b7d9"))
    draw_rect(Rect2(0, 0, 720, 110), Color("#173f2b"))

    draw_string(ThemeDB.fallback_font, Vector2(25, 45), "رحلة صيد", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(25, 85), "صيد الحجل - Multiplayer", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d9f99d"))
    draw_string(ThemeDB.fallback_font, Vector2(500, 45), "النقاط: " + str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(500, 80), "الطلقات: " + str(ammo), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#ffe08a"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 105), "🪙 الرصيد: %d عملة" % dog_coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#fde68a"))
    draw_string(ThemeDB.fallback_font, Vector2(255, 135), "النمط: %s" % hunting_mode_names[hunting_mode], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fff0a8"))
    if hunting_mode == 2:
        draw_string(ThemeDB.fallback_font, Vector2(480, 135), "🔥 طلقات التحدي: %d" % challenge_ammo, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(500, 105), "🏅 %s Lv.%d" % [hunter_rank, hunter_level], HORIZONTAL_ALIGNMENT_LEFT, 195, 16, Color("#bfdbfe"))
    var accuracy := 0.0 if shots_fired == 0 else (float(hits) / float(shots_fired)) * 100.0
    draw_string(ThemeDB.fallback_font, Vector2(25, 575), "الدقة: %d%%   السلسلة: %d   أفضل سلسلة: %d" % [roundi(accuracy), streak, best_streak], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#fff0a8"))
    draw_rect(Rect2(20, 610, 680, 78), Color("#315d39"))
    draw_string(ThemeDB.fallback_font, Vector2(35, 630), "المحافظة: " + selected_governorate + "   (اضغط للتغيير)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(35, 655), "المنطقة: " + selected_area + "   (اضغط للتغيير)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(35, 680), "القرية: " + selected_village + "   (اضغط للتغيير)", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(25, 715), "الوقت والطقس: " + _hunting_condition_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fff0a8"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 740), "تأثير الظروف على الصيد: %.2fx" % _world_difficulty(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#d9f99d"))
    draw_rect(Rect2(20, 555, 680, 10), Color("#294f32"))
    var round_progress := clampf(float(mission_progress) / float(maxi(1, mission_target)), 0.0, 1.0)
    draw_rect(Rect2(20, 555, 680 * round_progress, 10), Color("#d9f99d"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 765), "المرحلة %d | المهمة: %s — %d/%d | المكافأة: %d" % [mission_level, selected_village, mission_progress, mission_target, mission_reward], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffe08a"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 790), "التضاريس: %s | الأثر: %s | الطريدة: %s | الكلب: %s" % [terrain_type, track_type, ("مكشوفة" if prey_revealed else "مجهولة"), ("يتتبع الأثر" if dog_searching else "جاهز")], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c7f9cc"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 815), "الخطر: %d/3 | %s | كلبك: %s  | اضغط على منطقة الكلب لتغيير السلالة" % [prey_danger_level, ("طريدة مجهولة" if not prey_revealed else prey_species), dog_variant_names[dog_variant - 1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#dbeafe"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 840), "الطلقات في الجولة: %d | النمط: %s" % [round_shots, hunting_mode_names[hunting_mode]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#dbeafe"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 865), "السرعة %.1f | الشم %.1f | الدقة %d%%" % [_dog_stat("speed"), _dog_stat("scent"), int(_dog_stat("accuracy") * 100.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#fde68a"))
    draw_string(ThemeDB.fallback_font, Vector2(25, 890), "🐕 مستوى %d | XP %d/%d | نقاط تطوير: %d" % [dog_level, dog_xp, dog_xp_next, dog_upgrade_points], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#fef3c7"))
    if hunt_feedback_timer > 0.0 and not hunt_feedback.is_empty():
        draw_rect(Rect2(130, 300, 460, 70), Color("#173f2b"))
        draw_string(ThemeDB.fallback_font, Vector2(155, 345), hunt_feedback, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d9f99d") if hunt_feedback_success else Color("#fecaca"))
    if not dog_upgrade_open:
        draw_rect(Rect2(20, 915, 210, 50), Color("#315d39"))
        draw_rect(Rect2(250, 915, 210, 50), Color("#315d39"))
        draw_rect(Rect2(480, 915, 220, 50), Color("#315d39"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 947), "🛒 المتجر", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(275, 947), "🐕 الحظيرة", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
        var reward_state = "متاح +%d" % daily_reward_amount if daily_reward_claimed_date != _today_key() else "تم الاستلام"
        draw_string(ThemeDB.fallback_font, Vector2(500, 947), "🎁 اليومية: " + reward_state, HORIZONTAL_ALIGNMENT_LEFT, 195, 15, Color("#fde68a"))
        draw_string(ThemeDB.fallback_font, Vector2(500, 980), "📦 الصندوق: %d | آخر مكافأة: %d" % [reward_chest_count, last_hunt_reward], HORIZONTAL_ALIGNMENT_LEFT, 195, 14, Color("#c7f9cc"))
        draw_string(ThemeDB.fallback_font, Vector2(500, 1010), "🎯 يومي: %d/5  %d/10  %d/3" % [daily_mission_progress[0], daily_mission_progress[1], daily_mission_progress[2]], HORIZONTAL_ALIGNMENT_LEFT, 195, 13, Color("#fef3c7"))
        draw_string(ThemeDB.fallback_font, Vector2(500, 1038), "🏆 أسبوعي: %d/25" % weekly_mission_progress, HORIZONTAL_ALIGNMENT_LEFT, 195, 13, Color("#bfdbfe"))
    if dog_upgrade_open:
        draw_rect(Rect2(20, 890, 680, 190), Color(0.05, 0.08, 0.12, 0.96))
        draw_string(ThemeDB.fallback_font, Vector2(35, 920), "تطوير البونتر — نقطة لكل تطوير", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffffff"))
        draw_string(ThemeDB.fallback_font, Vector2(25, 955), "👃 شم", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffffff"))
        draw_string(ThemeDB.fallback_font, Vector2(190, 955), "🏃 سرعة", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffffff"))
        draw_string(ThemeDB.fallback_font, Vector2(350, 955), "🎯 دقة", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffffff"))
        draw_string(ThemeDB.fallback_font, Vector2(515, 955), "❤️ تحمل", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffffff"))
        draw_string(ThemeDB.fallback_font, Vector2(25, 990), "%.2f" % _dog_stat("scent"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fde68a"))
        draw_string(ThemeDB.fallback_font, Vector2(190, 990), "%.2f" % _dog_stat("speed"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fde68a"))
        draw_string(ThemeDB.fallback_font, Vector2(350, 990), "%d%%" % int(_dog_stat("accuracy") * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fde68a"))
        draw_string(ThemeDB.fallback_font, Vector2(515, 990), "%.2f" % _dog_stat("stamina"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#fde68a"))
    if kennel_shop_open:
        draw_rect(Rect2(15, 250, 690, 560), Color(0.04, 0.07, 0.10, 0.98))
        draw_string(ThemeDB.fallback_font, Vector2(35, 285), "متجر تجهيزات البونتر", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(35, 315), "الرصيد: %d عملة" % dog_coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fde68a"))
        for i in range(shop_items.size()):
            var y = 365.0 + i * 95.0
            var item = shop_items[i]
            var state = ("مجهز" if equipped_items[i] else "غير مجهز") if owned_items[i] else "%d عملة" % int(item["cost"])
            draw_rect(Rect2(30, y - 28, 650, 75), Color("#17324d") if owned_items[i] else Color("#12202c"))
            draw_string(ThemeDB.fallback_font, Vector2(50, y), str(item["name"]), HORIZONTAL_ALIGNMENT_LEFT, 280, 18, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(360, y), "تطوير: " + str(item["bonus"]), HORIZONTAL_ALIGNMENT_LEFT, 170, 15, Color("#c7f9cc"))
            draw_string(ThemeDB.fallback_font, Vector2(535, y), state, HORIZONTAL_ALIGNMENT_LEFT, 120, 15, Color("#fde68a"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 775), "اضغط على الأداة للشراء أو التجهيز/الإلغاء", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#dbeafe"))
        return

    if kennel_open:
        draw_rect(Rect2(15, 250, 690, 560), Color(0.04, 0.07, 0.10, 0.98))
        draw_string(ThemeDB.fallback_font, Vector2(35, 285), "حظيرة البونتر", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(35, 315), "الرصيد: %d عملة" % dog_coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fde68a"))
        for i in range(5):
            var y = 345.0 + i * 82.0
            var state = "مملوك" if owned_dogs[i] else "فتح بـ %d" % dog_unlock_costs[i]
            var active = " *" if dog_variant == i + 1 else ""
            draw_rect(Rect2(30, y - 25, 650, 65), Color("#17324d") if dog_variant == i + 1 else Color("#12202c"))
            draw_string(ThemeDB.fallback_font, Vector2(45, y), "%d. %s%s" % [i + 1, dog_variant_names[i], active], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
            draw_string(ThemeDB.fallback_font, Vector2(500, y), state, HORIZONTAL_ALIGNMENT_LEFT, 160, 15, Color("#c7f9cc"))
        draw_string(ThemeDB.fallback_font, Vector2(45, 785), "اضغط على كلب لاختياره أو فتحه", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#dbeafe"))
        return

    # Simple in-engine Pointer silhouette so the game does not depend on external image files.
    var dog_pos = Vector2(570, 835)
    draw_circle(dog_pos + Vector2(-18, 0), 14, Color("#f4f1e8"))
    draw_circle(dog_pos + Vector2(-28, -5), 8, Color("#2b2522") if dog_variant % 2 == 0 else Color("#8a4b2a"))
    draw_line(dog_pos + Vector2(-4, 2), dog_pos + Vector2(24, 2), Color("#f4f1e8"), 7)
    draw_line(dog_pos + Vector2(15, 2), dog_pos + Vector2(25, -14), Color("#f4f1e8"), 4)
    draw_line(dog_pos + Vector2(2, 5), dog_pos + Vector2(-2, 20), Color("#f4f1e8"), 4)
    draw_line(dog_pos + Vector2(15, 5), dog_pos + Vector2(12, 22), Color("#f4f1e8"), 4)
    # Mini map: visual position of the selected hunting area.
    draw_rect(Rect2(470, 755, 225, 145), Color("#183b2a"))
    draw_rect(Rect2(480, 765, 205, 125), Color("#28563a"))
    var map_pos = _map_position_for_area()
    draw_circle(map_pos, 9.0, Color("#ffe08a"))
    draw_circle(map_pos, 16.0, Color(1, 1, 1, 0.25))
    draw_string(ThemeDB.fallback_font, Vector2(485, 885), selected_area, HORIZONTAL_ALIGNMENT_LEFT, 195, 15, Color.WHITE)

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

    # Dynamic prey.
    if partridge_visible:
        if not prey_revealed:
            draw_circle(target, 18, Color("#b7c7a1"))
            draw_string(ThemeDB.fallback_font, Vector2(target.x - 95, target.y - 28), "🔎 أثر: " + track_type, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#fff0a8"))
        elif prey_species == "الذئب":
            draw_circle(target, 40, Color("#5b6470"))
            draw_circle(target + Vector2(-30, -22), 22, Color("#6b7280"))
            draw_string(ThemeDB.fallback_font, Vector2(target.x - 45, target.y - 62), "🐺 ذئب", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fecaca"))
        elif prey_species == "الضبع":
            draw_circle(target, 44, Color("#806f54"))
            draw_circle(target + Vector2(-32, -22), 22, Color("#9a8767"))
            draw_string(ThemeDB.fallback_font, Vector2(target.x - 45, target.y - 66), "🦴 ضبع", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fed7aa"))
        elif prey_species == "الأرنب البري":
            draw_circle(target, 28, Color("#8b7355"))
            draw_circle(target + Vector2(22, -18), 18, Color("#9a8060"))
            draw_line(target + Vector2(28, -30), target + Vector2(30, -55), Color("#9a8060"), 8)
            draw_line(target + Vector2(15, -31), target + Vector2(12, -56), Color("#9a8060"), 8)
        elif prey_species == "السمان":
            draw_circle(target, 28, Color("#6f4e37"))
            draw_circle(target + Vector2(-22, -18), 16, Color("#806044"))
            draw_circle(target + Vector2(-30, -20), 5, Color.BLACK)
        elif prey_species == "الحمام البري":
            draw_circle(target, 24, Color("#718096"))
            draw_circle(target + Vector2(-20, -18), 14, Color("#94a3b8"))
            draw_line(target + Vector2(5, 0), target + Vector2(42, -22), Color("#a8b4c4"), 9)
        elif prey_species == "الدراج":
            draw_circle(target, 48, Color("#7c4a25"))
            draw_circle(target + Vector2(-32, -25), 20, Color("#256d4a"))
            draw_circle(target + Vector2(-45, -29), 6, Color.BLACK)
        else:
            draw_circle(target, 48, Color("#6b4226"))
            draw_circle(target + Vector2(-28, -22), 23, Color("#80502d"))
            draw_circle(target + Vector2(-43, -27), 7, Color.BLACK)
            draw_circle(target + Vector2(-45, -29), 3, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(target.x - 70, target.y - 65), prey_species, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#fff0a8"))
        if prey_species == "الأرنب البري":
            draw_circle(target, 28, Color("#8b7355"))
            draw_circle(target + Vector2(22, -18), 18, Color("#9a8060"))
            draw_line(target + Vector2(28, -30), target + Vector2(30, -55), Color("#9a8060"), 8)
            draw_line(target + Vector2(15, -31), target + Vector2(12, -56), Color("#9a8060"), 8)
        elif prey_species == "السمان":
            draw_circle(target, 28, Color("#6f4e37"))
            draw_circle(target + Vector2(-22, -18), 16, Color("#806044"))
            draw_circle(target + Vector2(-30, -20), 5, Color.BLACK)
        elif prey_species == "الحمام البري":
            draw_circle(target, 24, Color("#718096"))
            draw_circle(target + Vector2(-20, -18), 14, Color("#94a3b8"))
            draw_line(target + Vector2(5, 0), target + Vector2(42, -22), Color("#a8b4c4"), 9)
        elif prey_species == "الدراج":
            draw_circle(target, 48, Color("#7c4a25"))
            draw_circle(target + Vector2(-32, -25), 20, Color("#256d4a"))
            draw_circle(target + Vector2(-45, -29), 6, Color.BLACK)
        else:
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
