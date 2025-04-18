extends Control

signal start_dialog(label)
signal change_room(label)
signal start_action_timer(actions, callback)
signal change_audio(song)

var hidden_sprites = null
var dialog_ongoing = false

func _ready():
	var children = $state_handler.get_children()
	children.append($state_handler)
	
	for node in children:
		var signal_list = node.get_signal_list()
		for sig in signal_list:
			if sig['name'] == "start_dialog":
				node.connect("start_dialog", self, "start_dialog")
			if sig['name'] == "change_room":
				node.connect("change_room", self, "change_room")
			if sig['name'] == "set_hidden_sprite":
				node.connect("set_hidden_sprite", self, "set_hidden_sprite")
			if sig['name'] == "start_action_timer":
				node.connect("start_action_timer", self, "start_action_timer")
			if sig['name'] == "change_audio":
				node.connect("change_audio", self, "change_audio")
			if sig['name'] == "stop_all_hovering":
				node.connect("stop_all_hovering", get_parent().get_parent(), "stop_all_hovering")
			if sig['name'] == "start_all_hovering":
				node.connect("start_all_hovering", get_parent().get_parent(), "start_all_hovering")

	
func set_hidden_sprite(sprites):
	if hidden_sprites != null:
		for sprite in hidden_sprites:
			sprite.show()
	hidden_sprites = sprites
	if sprites:
		for sprite in sprites:
			sprite.hide()
	
func update_state(state, end = false):
	if end:
		$state_handler.update_state_end(state)
	else:
		$state_handler.update_state(state)
	if hidden_sprites != null:
		for sprite in hidden_sprites:
			sprite.hide()

func init_state(state):
	$state_handler.init_state(state)

func play_default_music(state):
	$state_handler.play_default_music(state)
	
func start_dialog(label, sprites, blackout_label=null):
	if dialog_ongoing:
		return
	else:
		dialog_ongoing = true
		
	if sprites != null:
		for sprite in sprites:
			sprite.hide()
	hidden_sprites = sprites
	emit_signal('start_dialog', label, blackout_label)

func end_dialog():
	dialog_ongoing = false
	if hidden_sprites != null:
		for sprite in hidden_sprites:
			sprite.show()
	hidden_sprites = null

func change_room(label):
	emit_signal('change_room', label)

func start_action_timer(actions, callback):
	emit_signal('start_action_timer', actions, callback)
	
func change_audio(song):
	emit_signal('change_audio', song)
	
