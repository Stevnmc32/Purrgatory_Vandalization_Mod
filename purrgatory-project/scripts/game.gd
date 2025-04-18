extends Node2D

signal return_to_main()
signal animation_tick()

export var default_room = ''
var save_ticker = 0

var savefile = ""

var state = {
	'true': true
}

var _state = {
	'true': true,
	'unlocked_commons_door': true,
	'unlocked_meowseum_door': true,
	'_inv_business_card': true,
	'numa_at_commons': true
}

var tori_test_state = {
	'true': true,
	'saw_tori_intro': true,
	'met_tori': true,
	'tori_train_complete': true,
	'tori_park_complete': true#,
	#'tori_closet_complete': true
}

var sean_test_state = {
	'true': true,
	'met_sean': true,
	'sean_went_to_piano': true #,
	# '_inv_battery1': true,
	# '_inv_battery2': true
}

var natalie_test_state = {
	'true': true,
	'saw_natalie_intro': true,
	'returned_draw_a_paw': true,
	'natalie_finished_drawing3': true,
	'natalie_completed_mural': true,
	'natalie_working_on_nocturnal': true
}

var oliver_test_state = {
	'met_natalie': true,
	'true': true,
	'fed_kyungsoon_book': true,
	'met_kyungsoon': true,
	'met_oliver': true,
	'asked_ks_about_door': true,
	'checked_out_book': true,
	'tried_door': true,
	'book_state': true,
	'oliver_questioned': true,
	'_inv_commons_key': true,
	'seen_study': true,
	'_inv_chess_letter': true,
	'tori_visited_oliver': true,
	'oliver_asked_for_soda': true,
	'house_cat_pushed_glass': true,
	'comforted_oliver': true,
	'oliver_in_study': false
}

var numa_test_state = {
	'true': true,
	'fed_kyungsoon_book': true,
	'met_kyungsoon': true,
	'met_oliver': true,
	'asked_ks_about_door': true,
	'checked_out_book': true,
	'tried_door': true,
	'_inv_commons_key': true,
	'unlocked_commons_door': true,
	'met_numa': true,
	'numa_helping': true,
	'numa_snooped': true,
	'numa_started_poem': true,
	'numa_finished_poem': true,
	'numa_started_flowers': true,
	'flower_fails': 0,
	'numa_finished_flowers': true,
	'numa_started_food': true,
	'numa_progressed_food': true,
	'numa_finished_food': true,
	'met_elijah': true, 
	'numa_quest_complete': true,
	'ks_quest_complete': true,
	'ks_at_commons': true,
	'numa_at_commons': true
}

var format_dict = {
	'player': '',
	'player_upper': '',
	'they': '',
	'them': '',
	'their': '',
	'theirs': '',
	'themself': ''
}

var block = null
var meowkov_json = null
var action_timers = []
var fade_out = false
var current_audio = null
var skip = false
var main_audio = null

# i'm nearing the end of my rope...
# below is some state that needs to be saved, but isn't strings or numbers
# basically the drawings
var mural_drawing = null
var draw_a_paw_drawing = null

var seen_blocks = []

onready var room = get_node('content/room')
onready var ui = get_node('content/ui')

# this keeps track of the animation state
var anim_time = 0
var anim_framerate = 2

func _ready():
	randomize() # seed random
	change_audio(null) # load default audio (none)

	# load meowkov chain
	var f = File.new()
	load_meowkov_chain(f)

	# interrupt the default quit behavior (see _notification())
	get_tree().set_auto_accept_quit(false)

	# load seen blocks
	if f.file_exists("user://seen_blocks.save"):
		f.open("user://seen_blocks.save", File.READ)
		seen_blocks = parse_json(f.get_line())
		if !seen_blocks:
			seen_blocks = []
		f.close()
		
	# cursor
	Input.set_custom_mouse_cursor(load("res://assets/draw_cursor.png"), Input.CURSOR_HELP)
	
	# connect to language global
	Language.connect("language_changed", self, "_on_language_changed")

func load_meowkov_chain(f):
	f.open("res://scripts/procgen/meowutkov_edited.json", File.READ)
	meowkov_json = JSON.parse(f.get_as_text())
	f.close()
	

func _notification(what):
	# when the user quits...
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		
		# instead of doing the inane stuff below i'm just going to label the button "save and return"
		# we still need to attempt to autosave, though
		var f = File.new()
		f.open("user://seen_blocks.save", File.WRITE)
		f.store_line(to_json(seen_blocks))
		f.close()
		
		save(-1, false) # -1 is the autosave slot
		
		get_tree().quit()
	
		# save the changes to options
		# (i'm doing it here as well as when they press "back" in case they quit
		#   while on the options menu)
		
		# this won't trigger if the game crashes
		# so if you're in the options menu and the game crashes,
		#   you'll have to redo any changes you made
		# idk if it triggers if you force quit the game or shut off the computer
		
		#if visible:
		#	$meta_ui/options_menu.save_options()
		#else:
		#	get_node('../options_menu').save_options()

		#get_tree().quit()

func _process(delta):
	# animation stuff
	anim_time += delta
	while anim_time > 1.0 / anim_framerate:
		emit_signal('animation_tick')
		anim_time -= 1.0 / anim_framerate
	
	# other stuff
	if fade_out:
		var a = $white_cover.color.a
		if a == 1:
			fade_out = false
			$delay_timer.start()

			# turn off these two states in case they are currently overriding the audio
			# (else the audio system won't register the "null" command)
			state['blackout_music'] = false
			state['purrgatory_blues_loop'] = false
			# then turn off the audio
			change_audio(null)
			AudioServer.set_bus_mute(0, true)
			
			yield($delay_timer, 'timeout')

			emit_signal('return_to_main')
			$meta_ui.show() # bc it might have been disabled by the credits
			$white_cover.color = Color(1, 1, 1, 0)
			room.remove_room()
			$meta_ui/pause_menu.hide_custom() # hide it directly instead of using close_pause_menu()
			# bc you're not returning to the game			
			
			$meta_ui/exit_confirm.hide()
			$white_cover.hide()
			
		else:
			a = min(a + 2 * delta, 1)
			AudioServer.set_bus_volume_db(0, AudioServer.get_bus_volume_db(0) - 40 * delta)
			$white_cover.color = Color(1, 1, 1, a)

func start_action_timer(actions, callback):
	action_timers.append([actions, callback])

func increment_action_timers():
	var new_list = []
	for action_timer in action_timers:
		action_timer[0] = action_timer[0] - 1
		if action_timer[0] <= 0:
			state[action_timer[1][0]] = action_timer[1][1]
		else:
			new_list.append(action_timer)
	action_timers = new_list

func change_room(label):
	var stop_hovering = false
	# deal with PolygonButton hovering nonsense if you're changing rooms DURING dialog
	if ui.visible:
		stop_hovering = true
		
	increment_action_timers()
	if label == '_prev':
		room.change_room(room.prev_room_label, state)
	elif label == room.get_current_room():
		return
	else:
		room.change_room(label, state)
		
		# a little hack: going into the draw-a-paw minigame should close the inventory
		if label == "draw_a_paw" and $meta_ui/dropdown.items_shown:
			$meta_ui/dropdown.toggle_items() 
	
	if stop_hovering:
		room.stop_all_hovering()
		
	load_mural()

func start_dialog(label, blackout_label=null):
	
	
	if state.get('blackout') and blackout_label:
		label = blackout_label
		
	block = $dialog_handler.get_block(label, state)
	ui.show_ui()
	$meta_ui/history_button2.hide()
	room.start_dialog()
	
	# handle skip stuff before updating the ui so it knows if it should TTS or not
	if seen_blocks.has(block['label']):
		enable_skip()
		if skip:
			skip()
	else:
		disable_skip()
		if skip:
			turn_off_skip()

	var choices_text = []
	for choice in block['choices'][Language.language]:
		choices_text.append(format_text(choice[0]))
	var text = block['text'][Language.language]

	if text != null:
		text = format_text(text)
	
	var speaker = block['speaker'][Language.language]
	if speaker != null:
		var speaker_format_dict = { }
		for key in ['tori', 'sean', 'elijah', 'numa']:
			if state.get('met_' + key):
				speaker_format_dict[key] = key
			else:
				if Language.language == 0:
					speaker_format_dict[key] = '???'
				elif Language.language == 1:
					speaker_format_dict[key] = '¿¿??'
				
		speaker = speaker.format(speaker_format_dict)
		
		if speaker == 'you' and format_dict['player']:
			# "you" is used even in foreign language translations to denote "replace with player's name"
			# however, in the very first part of the game before the player inputs their name, "you" must be translated (eg. to "tú")
			speaker = format_dict['player']

	ui.update_ui(speaker, block['sprites'], text, choices_text)
	
	for pair in block['states']:
		state[pair[0]] = pair[1]
	room.update_state(state)
	
	for pair in block['states']:
		check_special_states(pair)
		
	room.stop_all_hovering()
	$draw.hide()

func end_dialog():
	ui.hide_ui()
	$meta_ui/history_button2.show()
	room.end_dialog()
	room.start_all_hovering()
	$draw.show()
	block = null

# block = {
#    'text': 'hello i'm oliver',
#    'choices': [['what\'s up', 'oliver_whats_up'], ['..', 'oliver_sdflkjslf']]
#     ...
#    'next': 150
# }

# clicking the text box goes through this function, so that the player can't
# click through text while skipping.
# the skipper goes directly to update_dialog.
func update_dialog_button_clicked():
	if not skip:
		update_dialog(-1)

func update_dialog(b: int):
	# $meta_ui/debug/Label.text = str(state)
	
	# mark the previous block as seen
	seen_blocks.append(block['label'])
	
	# autosave every so often. it's also saved whenever you exit (though not if you crash)
	save_ticker += 1
	if save_ticker % 15 == 0:
		var f = File.new()
		f.open("user://seen_blocks.save", File.WRITE)
		f.store_line(to_json(seen_blocks))
		f.close()
		
		save(-1, false) # -1 is the autosave slot
		
	# if there's no choice, get the next block directly
	if b == -1:
		block = $dialog_handler.get_block(block['next'], state)
	# else if there's a choice, use the parameter to decide
	else:
		block = $dialog_handler.get_block(block['choices'][Language.language][b][1], state)

	if block == null:
		end_dialog()
		if skip:
			turn_off_skip()
		$meta_ui/history.add_space()
		room.update_state(state, true) # mark it as an end
		
		for pair in state:
			check_special_states([pair, state[pair]])
			
	else:
		# handle skip stuff before updating the ui so it knows if it should TTS or not
		if seen_blocks.has(block['label']):
			enable_skip()
			if skip:
				skip()
		else:
			disable_skip()
			if skip:
				turn_off_skip()

		var choices_text = []
		for choice in block['choices'][Language.language]:
			choices_text.append(format_text(choice[0]))
		var text = block['text'][Language.language]

		if text != null:
			text = format_text(text)

		var speaker = block['speaker'][Language.language]
		if speaker != null:
			var speaker_format_dict = { }
			for key in ['tori', 'sean', 'elijah', 'numa']:
				if state.get('met_' + key):
					speaker_format_dict[key] = key
				else:
					if Language.language == 0:
						speaker_format_dict[key] = '???'
					elif Language.language == 1:
						speaker_format_dict[key] = '¿¿??'
					
			speaker = speaker.format(speaker_format_dict)
			
			if speaker == 'you' and format_dict['player']:
				speaker = format_dict['player']
	
		ui.update_ui(speaker, block['sprites'], text, choices_text)
		
		for pair in block['states']:
			state[pair[0]] = pair[1]
		room.update_state(state)
		
		for pair in block['states']:
			check_special_states(pair)

# this handles variable text like {player}, {they}{'s/'re}, etc.
func format_text(text):
	text = text.format(format_dict)

	# english
	if Language.language == 0: 
		var regex = RegEx.new()
		regex.compile('{([^/]+)/([^}]+)}')
		if 'they' in format_dict and format_dict['they'] == 'they':
			text = regex.sub(text, '$1', true)
		else:
			text = regex.sub(text, '$2', true)
			
	# spanish
	elif Language.language == 1:
		var regex = RegEx.new()
		regex.compile('{([^/]*)/([^/]*)/([^}]*)}')
		
		# this ensures english-only saves from older versions of purrgatory get updated with spanish equivalents
		if not (\
		state.get('_pronombre_el') or\
		state.get('_pronombre_ella') or\
		state.get('_pronombre_elle') or\
		state.get('_pronombre_personalizado')\
		):
			if 'they' in format_dict and format_dict['they'].length() > 0:
				if format_dict['they'] == 'he':
					state['_pronombre_el'] = true
				elif format_dict['they'] == 'she':
					state['_pronombre_ella'] = true
				else:
					state['_pronombre_elle'] = true
			# i guess technically this means if you have an old version of purrgatory where you put 
			# a blank for "they" then this won't work and you'll see all the {o/a/e}'s
			# but whatever
		
		if state.get('_pronombre_el'):
			text = regex.sub(text, '$1', true)
		
		elif state.get('_pronombre_ella'):
			text = regex.sub(text, '$2', true)
		
		elif state.get('_pronombre_elle'):
			text = regex.sub(text, '$3', true)
		
		elif state.get('_pronombre_personalizado'):
			# here we handle EVERY CASE manually because... why not
			var t = state.get('_terminacion')
			text = text.replacen('{él/ella/elle}', state.get('_pronombre'))\
					   .replacen('{/a/e}', ('' if t == 'o' else t))\
					   .replacen('{e/a/e}', ('e' if t == 'o' else t))\
					   .replacen('{el/la/le}', ('el' if t == 'o' else 'l' + t))\
					   .replacen('{o/a/e}', t)\
					   .replacen('{o/a/ue}', ('u' + t if t in ['i', 'e'] else t))\
					   .replacen('{ooo/aaa/eee}', t)
					   
		else:
			print('error: no pronouns set in spanish (spain)')
	
	return text
	
func _on_language_changed(lang):
	# this is called whenever.... yeah the language is changed
	# this is mostly copied from update_dialog and start_dialog... i know, not DRY, but who cares
	if block and ui.visible:
		var choices_text = []
		for choice in block['choices'][lang]:
			choices_text.append(format_text(choice[0]))
		var text = block['text'][lang]
	
		if text != null:
			text = format_text(text)
	
		var speaker = block['speaker'][lang]
		if speaker != null:
			var speaker_format_dict = { }
			for key in ['tori', 'sean', 'elijah', 'numa']:
				if state.get('met_' + key):
					speaker_format_dict[key] = key
				else:
					if Language.language == 0:
						speaker_format_dict[key] = '???'
					elif Language.language == 1:
						speaker_format_dict[key] = '¿¿??'
					
			speaker = speaker.format(speaker_format_dict)
			
			if speaker == 'you' and format_dict['player']:
				speaker = format_dict['player']
	
		ui.update_ui(speaker, null, text, choices_text)
	
func set_player_name():
	var text = ui.get_node('name_input/text').get_text().to_lower()
	if text.length() != 0:
		format_dict['player'] = text

		if ui.get_node('name_input/pronouns/they').pressed:
			# english pronouns
			state['_pronouns_they'] = true
			format_dict['they'] = 'they'
			format_dict['them'] = 'them'
			format_dict['their'] = 'their'
			format_dict['theirs'] = 'theirs'
			format_dict['themself'] = 'themself'
			# spanish pronouns
			state['_pronombre_elle'] = true
			# all occurences of variable gender in spanish are written in three parts like {él/ella/elle}
			# so no need to add anything to the format dict; everything is based on the state dict
			# also, if you choose elle/-e in spanish, the english is set to they/them
			# and vice versa, and same for the other pronouns

		elif ui.get_node('name_input/pronouns/she').pressed:
			state['_pronouns_she'] = true
			format_dict['they'] = 'she'
			format_dict['them'] = 'her'
			format_dict['their'] = 'her'
			format_dict['theirs'] = 'hers'
			format_dict['themself'] = 'herself'
			# spanish pronouns
			state['_pronombre_ella'] = true

		elif ui.get_node('name_input/pronouns/he').pressed:
			state['_pronouns_he'] = true
			format_dict['they'] = 'he'
			format_dict['them'] = 'him'
			format_dict['their'] = 'his'
			format_dict['theirs'] = 'his'
			format_dict['themself'] = 'himself'
			# spanish pronouns
			state['_pronombre_el'] = true

		elif ui.get_node('name_input/pronouns/custom').pressed:
			# if custom pronouns are entered in english...
			if Language.language == 0:
				state['_pronouns_custom'] = true
				var pronoun_inputs = ui.get_node('name_input/custom_pronouns/inputs/0')
				format_dict['they'] = pronoun_inputs.get_node('they').text
				format_dict['them'] = pronoun_inputs.get_node('them').text
				format_dict['their'] = pronoun_inputs.get_node('their').text
				format_dict['theirs'] = pronoun_inputs.get_node('their').text + 's' # this isn't technically correct but whatever
				format_dict['themself'] = pronoun_inputs.get_node('them').text + 'self'
				# ...the spanish version is automatically set to elle
				state['_pronombre_elle'] = true
				
			# and if a custom pronoun is entered in spanish...
			elif Language.language == 1:
				state['_pronombre_personalizado'] = true
				var pronoun_inputs = ui.get_node('name_input/custom_pronouns/inputs/1')
				# this may be confusing, but _pronombre and _terminacion are only defined if _pronombre_personalizado
				# is true; otherwise there's no need for them
				state['_pronombre'] = pronoun_inputs.get_node('pronombre').text
				state['_terminacion'] = pronoun_inputs.get_node('terminacion').text
				# ...and the english version is automatically set to they/them
				state['_pronouns_they'] = true
				format_dict['they'] = 'they'
				format_dict['them'] = 'them'
				format_dict['their'] = 'their'
				format_dict['theirs'] = 'theirs'
				format_dict['themself'] = 'themself'
			
		ui.get_node('name_input').hide()
		ui.get_node('text_box').disabled = false
		update_dialog(-1)

func change_audio(song, play = true):
	if AudioServer.is_bus_mute(0):
		AudioServer.set_bus_mute(0, false)
	
	# two exceptions that override every other source of music
	if state.get('blackout_music'):
		song = 'Lights_Out'
	elif state.get('purrgatory_blues_loop'):
		song = 'purrgatory_blues_loop'

	if song == current_audio:
		return

	current_audio = song

	if song == null or song == '' or song == 'null':
		if main_audio:
			main_audio.fadeout()
			main_audio = null
	
	else:
		if main_audio:
			main_audio.fadeout()
			main_audio = null
		
		main_audio = load('res://scenes/FadeoutPlayer.tscn').instance()
		var stream = load('res://assets/audio/' + song + '.ogg')
		main_audio.volume_db = -6
		main_audio.name = 'main_audio'
		main_audio.stream = stream
		main_audio.set_bus('Music')
		add_child(main_audio)

		if play:
			main_audio.play()
		
		# the reason you might not want it to play immediately is if you're loading
		#   in from the main menu and you have to wait for the fadein to finish
		# at that point, main_audio.play() is called from elsewhere

func return_to_main():
	$white_cover.show()
	fade_out = true

func save(file, manual=true):		
	# save the drawings separately, if they exist
	# if the player is in the middle of drawing when they save, we have to retrieve the
	#   image first
	# (this is why we save images before the state: draw_a_paw needs to modify the state
	#  to store the x and y coordinates of the tip)
	savefile=str(file)
	if room.get_current_room() == "hallway2" and state.get('mural_drawing'): 
		room.current_room.get_node('state_handler').store_image()
		
	if mural_drawing:
		mural_drawing.save_png("user://mural" + str(file) + ".png")
	else:
		var dir = Directory.new()
		if dir.file_exists("user://mural" + str(file) + ".png"):
			dir.remove("user://mural" + str(file) + ".png")
	
	if room.get_current_room() == 'draw_a_paw':
		room.current_room.get_node('state_handler').store_image()
	
	if draw_a_paw_drawing:
		draw_a_paw_drawing.save_png("user://draw_a_paw" + str(file) + ".png")
	else:
		var dir = Directory.new()
		if dir.file_exists("user://draw_a_paw" + str(file) + ".png"):
			dir.remove("user://draw_a_paw" + str(file) + ".png")
	
	# also, if the player saved in the middle of ttt, it needs to be saved separately
	
	if room.get_current_room() == 'ttt':
		room.current_room.get_node('state_handler').save_ttt(file)
	else:
		var dir = Directory.new()
		if dir.file_exists("user://ttt_state" + str(file) + ".save"):
			dir.remove("user://ttt_state" + str(file) + ".save")
		if dir.file_exists("user://ttt_drawing" + str(file) + ".png"):
			dir.remove("user://ttt_drawing" + str(file) + ".png")
	
	# and flowerbed
	
	if room.get_current_room() == 'flowerbed' and state.get('flower_ongoing'):
		var state_handler = room.current_room.get_node('state_handler')
		state['flower_progress'] = state_handler.get_node('flower_progress').i - 1
		state['flower_time_left'] = state_handler.get_node('game_timer').time_left
	else:
		state['flower_progress'] = null
		state['flower_time_left'] = null
		
	# and climb
	
	if room.get_current_room() == 'dropoff_long':
		var state_handler = room.current_room.get_node('state_handler')
		state['dropoff_climbing'] = state_handler.climbing
		state['dropoff_lost_grip'] = state_handler.lost_grip
		state['dropoff_progress'] = state_handler.progress
		state['dropoff_stamina'] = state_handler.get_node('_game/ProgressBar').value
	else:
		state['dropoff_climbing'] = null
		state['dropoff_lost_grip'] = null
		state['dropoff_progress'] = null
		state['dropoff_stamina'] = null
			
	# get the timestamp
	var months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
	var ampm = ['am', 'pm']
	var datetime = OS.get_datetime()

	var format = '%s %d, %d - %d:%02d %s'
	var timestamp = format % [
		months[datetime['month'] - 1],
		datetime['day'],
		datetime['year'],
		((datetime['hour'] - 1) % 12) + 1,
		datetime['minute'],
		ampm[datetime['hour'] / 12]
	]

	# make a dict
	var save_dict = {
		"state_dict": state,
		"room": room.get_current_room(),
		"prev_room": room.prev_room_label,
		"block": block,
		"format_dict": format_dict,
		"action_timers": action_timers,
		"sprites": ui.get_sprites(),
		"choices": ui.get_choices(),
		"text": ui.get_text(),
		"speaker": ui.get_speaker(),
		"hidden_sprites": room.get_hidden_sprites(),
		"music": current_audio,
		"timestamp": timestamp,
		"history": $meta_ui/history.history,
		"inventory": $meta_ui/dropdown.get_inv_list(),
		"quest_log": $meta_ui/dropdown.get_quest_log()
	}

	# save a dict
	var save_game = File.new()
	save_game.open("user://save" + str(file) + ".save", File.WRITE)
	save_game.store_line(to_json(save_dict))
	save_game.close()
			
	var dark_covers = $content/dark_covers
	
	# take a screenshot by moving all the relevant nodes to the "ss" viewport (unless it's an autosave)
	if manual:
		$content.remove_child(room)
		$content.remove_child(dark_covers)
		$content.remove_child(ui)
		
		# some ui elements get hidden when you're in the pause menu
		# thankfully, the only elements we really need to be present are the text box and choices
		# so we'll temporarily show them
		var ui_visible = true
		if not ui.get_node('text_box').visible:
			ui_visible = false
			ui.get_node('text_box').show()
			ui.get_node('choices').show()
		
		$ss.add_child(room)
		$ss.add_child(dark_covers)
		$ss.add_child(ui)
		var neg = $negative_cover.duplicate()
		$ss.add_child(neg)
		$ss_tex.show()
	
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	
		# grab the texture from the "ss" viewport
		var img = $ss.get_texture().get_data()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		img.save_png("user://thumb" + str(file) + ".png")
	
		# then move the nodes back
		$ss.remove_child(room)
		$ss.remove_child(dark_covers)
		$ss.remove_child(ui)
		$ss.remove_child(neg)
		$content.add_child(room)
		$content.add_child(dark_covers)
		$content.add_child(ui)
		$ss_tex.hide()
		
		if not ui_visible:
			ui.get_node('text_box').hide()
			ui.get_node('choices').hide()

		if get_tree().get_root().get_node('main').web_build:
			$meta_ui/save_menu.hide()
			$meta_ui/save_waiting.show()
			yield(get_tree().create_timer(8.0), 'timeout')
			
		# ok done
		$meta_ui/save_menu.hide()
		$meta_ui/save_waiting.hide()
		$meta_ui/save_confirm.show()
	

func load_game_while_playing(file):
	load_game(file)
	if main_audio:
		main_audio.play()
	$meta_ui/load_menu.hide()
	$meta_ui/load_confirm.show()

func load_game(file):
	savefile=str(file)
	var save_game = File.new()
	if not save_game.file_exists("user://save" + str(file) + ".save"):
		reset_state(true)
		return

	# temporarily mute audio to prevent artifacts
	AudioServer.set_bus_mute(0, true)
	
	save_game.open("user://save" + str(file) + ".save", File.READ)
	var save_dict = parse_json(save_game.get_line())
	save_game.close()

	reset_state(false) # reset state, but don't mess with the room
	# (resetting the room to the default and then immediately changing it to the new room was
	#   causing a bug where the defulut room didn't get deleted)
	state = save_dict["state_dict"]
	format_dict = save_dict["format_dict"]
	action_timers = save_dict["action_timers"]
	block = save_dict["block"]
	
	# drawings need to be loaded separately
	
	var f = File.new()
	if f.file_exists("user://mural" + str(file) + str(room.get_current_room()) + ".png"):
		mural_drawing = Image.new()
		mural_drawing.load("user://mural" + str(file) + str(room.get_current_room()) + ".png")
	else :
		mural_drawing = null
		
	if f.file_exists("user://draw_a_paw" + str(file) + ".png"):
		draw_a_paw_drawing = Image.new()
		draw_a_paw_drawing.load("user://draw_a_paw" + str(file) + ".png")
	else:
		draw_a_paw_drawing = null

	# ok back to room stuff
	
	room.change_room(save_dict["room"], state, false, true)
	change_audio(save_dict["music"], false)
	room.set_hidden_sprites(save_dict["hidden_sprites"])
	room.update_state(state)
	
	room.prev_room_label = save_dict["prev_room"]

	if block:
		ui.show_ui()
		$meta_ui/history_button2.hide()
		room.start_dialog()
		ui.update_ui(save_dict["speaker"], save_dict["sprites"], save_dict["text"], save_dict["choices"], false)

	$meta_ui/dropdown.load_inv(save_dict["inventory"])
	$meta_ui/dropdown.load_quest_log(save_dict["quest_log"])
	
	# wait until the ui is done updating so it doesn't interfere with the history
	yield(get_tree(), 'idle_frame')
	$meta_ui/history.load_history(save_dict["history"])
	
	
	yield(get_tree(), "idle_frame")
	AudioServer.set_bus_mute(0, false)
	
	# finally, if the player loaded into ttt, it needs to be loaded separately
	if room.get_current_room() == 'ttt':
		room.current_room.get_node('state_handler').load_ttt(file)
		
	# flowerbed just needs a little push
	if room.get_current_room() == 'flowerbed':
		room.current_room.get_node('state_handler').setup_game()
		if state.get('flower_ongoing'):
			var progress = 0
			var time = 0
			
			if state.get('flower_progress'):
				progress = state['flower_progress']
			if state.get('flower_time_left'):
				time = state['flower_time_left']
				
			room.current_room.get_node('state_handler').start_game(time, progress)
	
	# and climbing
	if room.get_current_room() == 'dropoff_long':
		room.current_room.get_node('state_handler').load_in(\
			state.get('dropoff_climbing'),\
			state.get('dropoff_lost_grip'),\
			state.get('dropoff_progress'),\
			state.get('dropoff_stamina')\
		)
		
	load_mural()
			
func reset_state(reset_room):
	end_dialog()
	
	ui.get_node('name_input').hide()
	ui.get_node('name_input/text').set_text('')
	ui.get_node('name_input/pronouns/they').pressed = true
	
	ui.get_node('name_input/custom_pronouns').hide()
	ui.get_node('name_input/custom_pronouns/inputs/0/they').text = "they"
	ui.get_node('name_input/custom_pronouns/inputs/0/them').text = "them"
	ui.get_node('name_input/custom_pronouns/inputs/0/their').text = "their"
	ui.get_node('name_input/custom_pronouns/inputs/1/pronombre').text = "elle"
	ui.get_node('name_input/custom_pronouns/inputs/1/terminacion').text = "e"
	
	state = {
		'true': true
	}
	format_dict = {
		'player': '',
		'player_upper': ''
	}
	
	action_timers = []
	block = null
	if reset_room:
		room.change_room(default_room, state, false)
	change_audio(null)
	
	$meta_ui/dropdown.load_inv([])
	$meta_ui/dropdown.load_quest_log([])
	$meta_ui/history.load_history([])
	
	mural_drawing = null
	draw_a_paw_drawing = null


func toggle_pause_menu():
	if $meta_ui/pause_menu.visible:
		close_pause_menu()
	else:
		open_pause_menu()
	
func open_pause_menu():
	$tts_node.stop()
	$meta_ui/pause_menu.show_custom()
	$draw.hide()

func close_pause_menu():
	$meta_ui/pause_menu.hide_custom()
	$draw.show()

func options_changed():
	var state_handler = room.find_node('state_handler', true, false)
	if state_handler and state_handler.has_method('options_changed'):
		state_handler.options_changed()

func save_confirmed():
	$meta_ui/save_confirm.hide()
	close_pause_menu()

func load_confirmed():
	$meta_ui/load_confirm.hide()
	close_pause_menu()

func toggle_skip():
	if ui.get_node('skip_button/x').visible:
		return
	if skip:
		turn_off_skip()
	else:
		turn_on_skip()

func turn_off_skip():
	skip = false
	ui.get_node('skip_button/box2').set_modulate(Color(1, 1, 1))
	$skip_timer.stop()

func turn_on_skip():
	skip = true
	ui.get_node('skip_button/box2').set_modulate(Color(0.85, 0.85, 0.85))
	skip()

func enable_skip():
	ui.get_node('skip_button/x').hide()

func disable_skip():
	ui.get_node('skip_button/x').show()

func skip():
	if block['choices'][0].size() == 0 and (block['states'].size() == 0 or block['states'][0][0] != 'no_skip'):
		# no_skip is used to prevent it from skipping the name input
		$skip_timer.start()

# examine an item from the inventory
func examine_item(_name):
	if not ui.is_visible():
		start_dialog('examine_' + _name)

func check_special_states(pair):
	if pair[0].substr(0,  5) == '_inv_':
		if pair[1]:
			$meta_ui/dropdown.add_to_inv(pair[0].substr(5, len(pair[0])))
		else:
			$meta_ui/dropdown.remove_from_inv(pair[0].substr(5, len(pair[0])))

	if pair[0].substr(0,  7) == '_quest_':
		if pair[1]:
			$meta_ui/dropdown.add_quest(pair[0].substr(7, len(pair[0])))
		else:
			$meta_ui/dropdown.remove_quest(pair[0].substr(7, len(pair[0])))

	if pair[0].substr(0,  6) == '_anim_' and pair[1]:
		state[pair[0]] = false

		var player = ui.get_node('AnimationPlayer')
		var anim = pair[0].substr(6, len(pair[0]))

		if player.has_animation(anim):
			player.play(anim)
		else:
			print('uh oh stinky this anim is missing: %s' % anim)

func test_add_quest():
	check_special_states([$meta_ui/dropdown/quest_debug.text, true])

func test_remove_quest():
	check_special_states([$meta_ui/dropdown/quest_debug.text, false])

func start_drawing():
	$draw/draw_texture.set_texture($draw/draw_viewport.get_texture())
	$draw.enable()
	$draw.mouse_filter = Control.MOUSE_FILTER_PASS
	$draw / draw_texture.mouse_filter = Control.MOUSE_FILTER_PASS
	$draw/done_button.show()
	$draw/erase_button.show()
	
func stop_drawing():
	$draw.disable()
	$draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$draw / draw_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$draw/done_button.hide()
	$draw/erase_button.hide()
	self.state["mural_drawing"] = false
	
	store_image()

func store_image():
	var texture = $draw / draw_texture.texture
	var final_img = null
	
	if texture:
		var new_img = texture.get_data()
		
		if $draw / loaded_texture.texture:
			final_img = $draw / loaded_texture.texture.get_data()
			final_img.blend_rect(new_img, Rect2(Vector2(0, 0), Vector2(1280, 720)), Vector2(0, 0))
		else :
			final_img = new_img
		
	mural_drawing = final_img
	if mural_drawing:
		mural_drawing.save_png("user://mural" + str(savefile) + str(room.get_current_room()) + ".png")
	else :
		var dir = Directory.new()
		if dir.file_exists("user://mural" + str(savefile) + str(room.get_current_room()) + ".png"):
			dir.remove("user://mural" + str(savefile) + str(room.get_current_room()) + ".png")

func erase_mural():
	$draw/draw_viewport/pen.to_erase=true
	$draw/loaded_texture.texture = null

func load_mural():
	#$draw/loaded_texture.set_texture(null)
	#$draw/draw_texture.set_texture(null)
	
	mural_drawing=null
	var f = File.new()
	if f.file_exists("user://mural" + str(savefile) + str(room.get_current_room()) + ".png"):
		mural_drawing = Image.new()
		mural_drawing.load("user://mural" + str(savefile) + str(room.get_current_room()) + ".png")
		$draw/loaded_texture.texture = ImageTexture.new()
		$draw/loaded_texture.texture.create_from_image(mural_drawing)
		$draw/draw_viewport/pen.to_erase=true
		$draw/draw_viewport/pen.to_load_mural=true
	else :
		mural_drawing = null
		$draw/loaded_texture.texture = null
		$draw/draw_viewport/pen.to_erase=true
	
	
		#$draw/draw_texture.texture=ImageTexture.new().create_from_image(Image.new().create(1280,720,false,Image.FORMAT_RGB8))
	

# this is called from the save/load screens when you delete your data
# just so that we can delete seen_blocks
func deleted_data():
	seen_blocks = []

# only used during the credits as of now
func disable_ui():
	$meta_ui.hide()



