class_name RecordsPanel
extends CanvasLayer


func _ready() -> void:
	layer = 25
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(420, 0)
	center.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "游戏记录"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(title)

	_add_spacer(vbox, 14)

	# 总览统计
	var stats_panel := PanelContainer.new()
	vbox.add_child(stats_panel)
	var stats_vbox := VBoxContainer.new()
	stats_panel.add_child(stats_vbox)

	_add_stat_row(stats_vbox, "历史最高质量", str(SaveManager.get_best_mass()))
	_add_stat_row(stats_vbox, "累计游玩次数", "%d 局" % SaveManager.get_total_games())
	_add_stat_row(stats_vbox, "累计游玩时长", _fmt_time(SaveManager.get_total_play_time()))

	_add_spacer(vbox, 14)

	# 历史记录标题
	var ht := Label.new()
	ht.text = "最佳记录  Top %d" % SaveManager.MAX_HIGH_SCORES
	ht.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ht.add_theme_font_size_override("font_size", 14)
	ht.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(ht)

	_add_spacer(vbox, 4)

	var scores: Array = SaveManager.get_high_scores()
	if scores.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "暂无记录，快去游玩吧！"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		vbox.add_child(empty_lbl)
	else:
		for i in scores.size():
			var raw: Variant = scores[i]
			if not raw is Dictionary:
				continue
			var entry: Dictionary = raw as Dictionary
			var crown: String = "★ " if i == 0 else "  "
			var row := Label.new()
			row.text = "%s%2d.  质量 %6d   时长 %s" % [
				crown, i + 1,
				int(entry.get("mass", 0)),
				_fmt_time(float(entry.get("time", 0)))
			]
			row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_theme_font_size_override("font_size", 13)
			var col := Color(1.0, 0.85, 0.2) if i == 0 else Color(0.82, 0.82, 0.82)
			row.add_theme_color_override("font_color", col)
			vbox.add_child(row)

	_add_spacer(vbox, 18)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(0, 42)
	close_btn.pressed.connect(func(): queue_free())
	vbox.add_child(close_btn)


func _add_stat_row(parent: VBoxContainer, label: String, value: String) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	hbox.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(val)


func _fmt_time(secs: float) -> String:
	var total: int = int(secs)
	var h: int = total / 3600
	var m: int = (total % 3600) / 60
	var s: int = total % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]


func _add_spacer(parent: Control, h: int) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)
