## Autoload: SaveManager
extends Node

const SAVE_PATH := "user://save_data.json"
const MAX_HIGH_SCORES := 10

var _data: Dictionary = {
	"player_name": "Player",
	"player_color": [0.2, 0.6, 1.0, 1.0],
	"best_mass": 0,
	"total_games": 0,
	"total_play_time": 0.0,
	"high_scores": [],
}


func _ready() -> void:
	_load()


# ── 读写 ──────────────────────────────────────────────

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	# JSON.parse_string 返回 Variant，必须显式注明
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		var d := parsed as Dictionary
		for key in d:
			_data[key] = d[key]


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


# ── 公共接口 ──────────────────────────────────────────

## 每局结束时调用。返回 true 表示创了历史新高
func record_game(peak_mass: float, survival_secs: float) -> bool:
	_data["total_games"] = int(_data.get("total_games", 0)) + 1
	_data["total_play_time"] = float(_data.get("total_play_time", 0.0)) + survival_secs

	var prev_best: float = float(_data.get("best_mass", 0))
	var is_new_best: bool = peak_mass > prev_best
	if is_new_best:
		_data["best_mass"] = int(peak_mass)

	# 安全地取出历史记录（Dictionary.get 返回 Variant，需先 cast 再操作）
	var scores: Array = _get_scores_array()
	scores.append({"mass": int(peak_mass), "time": snappedf(survival_secs, 0.1)})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["mass"]) > int(b["mass"])
	)
	if scores.size() > MAX_HIGH_SCORES:
		scores.resize(MAX_HIGH_SCORES)
	_data["high_scores"] = scores

	_save()
	return is_new_best


func save_player_prefs(pname: String, color: Color) -> void:
	_data["player_name"] = pname
	_data["player_color"] = [color.r, color.g, color.b, color.a]
	_save()


func get_best_mass() -> int:
	return int(_data.get("best_mass", 0))


func get_total_games() -> int:
	return int(_data.get("total_games", 0))


func get_last_player_name() -> String:
	return str(_data.get("player_name", "Player"))


func get_last_player_color() -> Color:
	var raw: Variant = _data.get("player_color", null)
	if raw is Array:
		var arr := raw as Array
		if arr.size() >= 3:
			return Color(float(arr[0]), float(arr[1]), float(arr[2]), 1.0)
	return Color(0.2, 0.6, 1.0)


func get_high_scores() -> Array:
	return _get_scores_array().duplicate()


func get_total_play_time() -> float:
	return float(_data.get("total_play_time", 0.0))


# ── 内部工具 ──────────────────────────────────────────

func _get_scores_array() -> Array:
	var raw: Variant = _data.get("high_scores", null)
	if raw is Array:
		return raw as Array
	return []
