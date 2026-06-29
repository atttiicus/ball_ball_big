class_name MainMenu
extends CanvasLayer

signal start_game(player_name: String, two_player: bool, color: Color)

var _name_input: LineEdit
var _skin_selector: SkinSelector
var _selected_color: Color = Color(0.2, 0.6, 1.0)


func _ready() -> void:
	layer = 20
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.15, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(320, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "球球大作战"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(title)

	_add_spacer(vbox, 30)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "输入昵称..."
	_name_input.text = SaveManager.get_last_player_name()
	_name_input.custom_minimum_size = Vector2(0, 40)
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_name_input)

	# 最高分小字（始终显示，无记录时提示"查看记录"）
	var best_lbl := Label.new()
	var best: int = SaveManager.get_best_mass()
	if best > 0:
		best_lbl.text = "历史最高：%d    累计 %d 局" % [best, SaveManager.get_total_games()]
	else:
		best_lbl.text = "暂无记录，点击「查看记录」可查看存档"
	best_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_lbl.add_theme_font_size_override("font_size", 12)
	best_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(best_lbl)

	_add_spacer(vbox, 10)

	var skin_label := Label.new()
	skin_label.text = "选择颜色"
	skin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skin_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(skin_label)

	_add_spacer(vbox, 4)

	var skin_center := CenterContainer.new()
	vbox.add_child(skin_center)
	_skin_selector = SkinSelector.new()
	_skin_selector.color_selected.connect(func(c): _selected_color = c)
	skin_center.add_child(_skin_selector)
	# 恢复上次选择的颜色
	var saved_color := SaveManager.get_last_player_color()
	_selected_color = saved_color
	_skin_selector.try_select_color(saved_color)

	_add_spacer(vbox, 16)

	var btn1 := Button.new()
	btn1.text = "单人游戏"
	btn1.custom_minimum_size = Vector2(0, 44)
	btn1.pressed.connect(func(): _emit_start(false))
	vbox.add_child(btn1)

	_add_spacer(vbox, 8)

	var btn3 := Button.new()
	btn3.text = "联网多人"
	btn3.custom_minimum_size = Vector2(0, 44)
	btn3.pressed.connect(_on_online_pressed)
	vbox.add_child(btn3)

	_add_spacer(vbox, 8)

	var records_btn := Button.new()
	records_btn.text = "查看记录"
	records_btn.custom_minimum_size = Vector2(0, 44)
	records_btn.pressed.connect(_on_records_pressed)
	vbox.add_child(records_btn)

	_add_spacer(vbox, 16)

	var quit_btn := Button.new()
	quit_btn.text = "退出游戏"
	quit_btn.custom_minimum_size = Vector2(0, 40)
	quit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_btn)

	_name_input.text_submitted.connect(func(_t): _emit_start(false))


func _on_online_pressed() -> void:
	var lobby := Lobby.new()
	# 将 lobby 挂到同一层，主菜单先隐藏
	get_parent().add_child(lobby)
	lobby.back_to_menu.connect(func(): show())
	lobby.start_online.connect(func(pname, _is_host, _addr):
		emit_signal("start_game", pname, false, _selected_color)
	)
	hide()


func _emit_start(two_player: bool) -> void:
	var pname := _name_input.text.strip_edges()
	if pname.is_empty():
		pname = "Player"
	emit_signal("start_game", pname, two_player, _selected_color)
	queue_free()


func _on_records_pressed() -> void:
	var panel := RecordsPanel.new()
	get_parent().add_child(panel)


func _add_spacer(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)
