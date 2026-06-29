class_name DeathScreen
extends CanvasLayer

signal respawn

var _info_label: Label
var _new_record_label: Label
var _scores_box: VBoxContainer


func _ready() -> void:
	layer = 20
	_build_ui()


func show_result(survived_seconds: float, peak_mass: float, rank: int) -> void:
	# 记录到存档，判断是否新纪录
	var is_new_best := SaveManager.record_game(peak_mass, survived_seconds)

	_info_label.text = "存活时间：%s    最大质量：%d    最终排名：第 %d 名" % [
		_fmt_time(survived_seconds), int(peak_mass), rank
	]

	_new_record_label.text = "★ 历史新高！" if is_new_best else ""
	_new_record_label.visible = is_new_best

	_refresh_scores()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "你被吃掉了！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(title)

	_add_spacer(vbox, 8)

	# 新纪录
	_new_record_label = Label.new()
	_new_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_new_record_label.add_theme_font_size_override("font_size", 22)
	_new_record_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_new_record_label.visible = false
	vbox.add_child(_new_record_label)

	_add_spacer(vbox, 6)

	# 本局信息
	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 15)
	_info_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(_info_label)

	_add_spacer(vbox, 14)

	# 历史最佳
	var ht := Label.new()
	ht.text = "历史最佳  Top %d" % SaveManager.MAX_HIGH_SCORES
	ht.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ht.add_theme_font_size_override("font_size", 14)
	ht.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(ht)

	_add_spacer(vbox, 4)

	_scores_box = VBoxContainer.new()
	vbox.add_child(_scores_box)

	_add_spacer(vbox, 16)

	# 统计小字
	var stats := Label.new()
	stats.text = "累计游玩：%d 局    总时长：%s" % [
		SaveManager.get_total_games(),
		_fmt_time(SaveManager.get_total_play_time())
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(stats)

	_add_spacer(vbox, 16)

	var btn := Button.new()
	btn.text = "再来一局"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.pressed.connect(func():
		emit_signal("respawn")
		queue_free()
	)
	vbox.add_child(btn)


func _refresh_scores() -> void:
	for child in _scores_box.get_children():
		child.queue_free()

	var scores: Array = SaveManager.get_high_scores()
	for i in scores.size():
		var raw: Variant = scores[i]
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw as Dictionary
		var row := Label.new()
		var crown: String = "★ " if i == 0 else "  "
		row.text = "%s%2d.  质量 %6d   时长 %s" % [
			crown, i + 1, int(entry.get("mass", 0)), _fmt_time(float(entry.get("time", 0)))
		]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 13)
		var col := Color(1.0, 0.85, 0.2) if i == 0 else Color(0.8, 0.8, 0.8)
		row.add_theme_color_override("font_color", col)
		_scores_box.add_child(row)


func _fmt_time(secs: float) -> String:
	var m := int(secs) / 60
	var s := int(secs) % 60
	return "%02d:%02d" % [m, s]


func _add_spacer(parent: Control, h: int) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)
