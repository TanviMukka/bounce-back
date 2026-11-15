extends CharacterBody2D

const SPEED = 900.0
const JUMP_VELOCITY = -900.0

var questions = [
	{"question": "you run into a wall. what do you do?", "button1": "(1) stay there and cry", "button2": "(2) go to the hospital", "correct": 2},
	{"question": "you forgot to send out the invites to your birthday party so nobody shows up. what do you do?", "button1": "(1) throw a fit", "button2": "(2) plan another party", "correct": 2},
	{"question": "your partner just broke up with you. what do you do?", "button1": "(1) try to move on", "button2": "(2) get revenge on them", "correct": 1},
	{"question": "you just got an F on your test. what do you do?", "button1": "(1) yell at your teacher", "button2": "(2) try to study more for the next one", "correct": 2},
	{"question": "you just got rejected from franklin university. what do you do?", "button1": "(1) re-apply next year", "button2": "(2) sue the school", "correct": 1},
]

var current_question := 0
var choice_active := false
var label: Label
var button1: Button
var button2: Button
var message_label: Label

func _ready() -> void:
	var scene = get_tree().current_scene
	button1 = scene.find_child("Button", true, false)
	button2 = scene.find_child("Button2", true, false)
	label = scene.find_child("Label", true, false)

	for i in range(questions.size()):
		var area = scene.find_child("ChoiceArea" + str(i + 1), true, false)
		if area:
			area.body_entered.connect(_on_area_entered.bind(i))
		else:
			print("Could not find ChoiceArea", i + 1)

	# Build the screen layout after the scene has finished loading
	setup_ui.call_deferred()

func setup_ui() -> void:
	var scene = get_tree().current_scene

	# A CanvasLayer keeps everything fixed on the screen
	var layer := CanvasLayer.new()
	layer.layer = 10
	scene.add_child(layer)

	# Question + buttons, stacked at the top of the screen
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	vbox.offset_top = 40
	vbox.offset_left = 100
	vbox.offset_right = -100
	vbox.add_theme_constant_override("separation", 30)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vbox)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	label.reparent(vbox)
	vbox.add_child(hbox)
	button1.reparent(hbox)
	button2.reparent(hbox)

	# Question text style
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)

	# Buttons are for display only: keyboard 1 / 2 does the choosing
	for b in [button1, button2]:
		b.custom_minimum_size = Vector2(350, 60)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 24)

	# Big centered text for the start and end screens
	message_label = Label.new()
	message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 56)
	message_label.add_theme_color_override("font_color", Color.WHITE)
	message_label.add_theme_color_override("font_outline_color", Color.BLACK)
	message_label.add_theme_constant_override("outline_size", 14)
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(message_label)

	show_ui(false)
	show_message("BOUNCE BACK\n\nJump across the platforms!", 4.0)  # start text

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			choose(1)
		elif event.keycode == KEY_2:
			choose(2)

func show_ui(on: bool) -> void:
	label.visible = on
	button1.visible = on
	button2.visible = on

func show_message(text: String, seconds: float = 0.0) -> void:
	message_label.text = text
	message_label.visible = true
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
		message_label.visible = false

func _on_area_entered(body: Node2D, index: int) -> void:
	if body != self or choice_active or index != current_question:
		return
	var q = questions[current_question]
	label.text = q["question"]
	button1.text = q["button1"]
	button2.text = q["button2"]
	show_ui(true)
	choice_active = true

func choose(picked: int) -> void:
	if not choice_active:
		return
	choice_active = false
	button1.visible = false
	button2.visible = false

	if picked == questions[current_question]["correct"]:
		current_question += 1
		if current_question >= questions.size():
			# Last question answered: show the end screen
			label.visible = false
			set_physics_process(false)
			show_message("THE END\n\nYou bounced back!")
			return
		label.text = "You bounced back!"
		await get_tree().create_timer(2.0).timeout
		if not choice_active:
			label.visible = false
	else:
		label.text = "You failed. You didn't bounce back..."
		set_physics_process(false)
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()

# Harmless leftover so an old signal connection doesn't cause an error
func _on_choice_area_body_entered(_body: Node2D) -> void:
	pass
