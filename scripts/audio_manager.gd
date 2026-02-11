extends Node

## AudioManager - Autoload singleton for music and SFX playback

const MUSIC_DIR = "res://assets/audio/music"
const SFX_DIR = "res://assets/audio/sfx"
const MUSIC_SILENT_DB = -80.0
const MUSIC_CROSSFADE_SECONDS = 1.5
const SFX_PLAYER_COUNT = 6
const VOLUME_STEP_DB = 2.0
const VOLUME_MIN_DB = -40.0
const VOLUME_MAX_DB = 0.0
const SFX_BASE_VOLUME_DB = 0.0
const SFX_HIT_REDUCED_DB = -6.0  # 50% volume ≈ -6 dB
const HIT_SFX_BUS = "HitSFX"

const MUSIC_MODE_OFF = "off"
const MUSIC_MODE_LOOP_ONE = "loop_one"
const MUSIC_MODE_LOOP_ALL = "loop_all"
const MUSIC_MODE_SHUFFLE = "shuffle"
const AUDIO_TOAST_SCRIPT: GDScript = preload("res://scripts/ui/audio_toast.gd")

var music_mode: String = MUSIC_MODE_LOOP_ALL
var music_track_id: String = ""
var music_tracks: Array = []
var current_track_index: int = -1
var current_player_index: int = 0
var is_crossfading: bool = false
var music_paused: bool = false
var paused_player_index: int = -1
var paused_position: float = 0.0

var music_players: Array = []
var sfx_players: Array = []
var sfx_streams: Dictionary = {}
var toast_ui: Node = null

# Signals
signal music_volume_changed(new_volume_db: float)

func _ready():
	randomize()
	_ensure_audio_buses()
	_init_toast_ui()
	_init_sfx_players()
	_init_music_players()
	_load_sfx_streams()
	_load_music_tracks()
	_apply_saved_volumes()
	_load_saved_music_settings()
	_start_music_if_enabled()
	_refresh_music_processing_state()
	set_process_unhandled_input(true)

func _process(_delta: float) -> void:
	if music_paused:
		return
	if music_mode != MUSIC_MODE_LOOP_ALL and music_mode != MUSIC_MODE_SHUFFLE:
		return
	if is_crossfading:
		return
	var player = _get_current_music_player()
	if player == null or not player.playing:
		return
	var stream = player.stream
	if stream == null:
		return
	var length = stream.get_length()
	if length <= 0.0:
		return
	var time_left = length - player.get_playback_position()
	if time_left <= MUSIC_CROSSFADE_SECONDS:
		_start_crossfade_to_next_track()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("audio_volume_down"):
		_adjust_music_volume(-VOLUME_STEP_DB)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("audio_volume_up"):
		_adjust_music_volume(VOLUME_STEP_DB)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("audio_prev_track"):
		_play_previous_track()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("audio_next_track"):
		_play_next_track()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("audio_toggle_pause"):
		_toggle_music_pause()
		get_viewport().set_input_as_handled()

func play_sfx(sfx_name: String) -> void:
	if not sfx_streams.has(sfx_name):
		push_warning("Unknown SFX: " + sfx_name)
		return
	var stream = sfx_streams[sfx_name]
	if stream == null:
		push_warning("Missing SFX stream: " + sfx_name)
		return
	var player = _get_available_sfx_player()
	if player == null:
		return
	player.bus = _get_sfx_bus(sfx_name)
	player.stream = stream
	player.volume_db = _get_sfx_volume_db(sfx_name)
	player.play()

func _get_sfx_volume_db(sfx_name: String) -> float:
	match sfx_name:
		"hit_brick", "hit_wall":
			return SFX_HIT_REDUCED_DB
		_:
			return SFX_BASE_VOLUME_DB

func _get_sfx_bus(sfx_name: String) -> String:
	match sfx_name:
		"hit_brick", "hit_wall":
			return HIT_SFX_BUS
		_:
			return "SFX"

func set_music_mode(mode: String) -> void:
	if mode == music_mode:
		return
	music_mode = mode
	if music_mode == MUSIC_MODE_OFF:
		_fade_out_and_stop_music()
		return
	if music_track_id == "":
		music_track_id = _get_default_track_id()
	if current_track_index == -1 or not _is_any_music_playing():
		_start_music_if_enabled()
		return
	if music_mode == MUSIC_MODE_LOOP_ONE:
		var track_index = _get_track_index_by_id(music_track_id)
		if track_index == -1:
			track_index = current_track_index
			music_track_id = music_tracks[track_index]["id"]
		_play_track(track_index, true)
		return
	_refresh_music_processing_state()

func set_music_track(track_id: String) -> void:
	if track_id == "":
		return
	music_track_id = track_id
	if music_mode != MUSIC_MODE_LOOP_ONE:
		return
	var track_index = _get_track_index_by_id(track_id)
	if track_index == -1:
		push_warning("Unknown music track: " + track_id)
		return
	_play_track(track_index, true)

func get_music_track_ids() -> Array:
	var ids: Array = []
	for track in music_tracks:
		ids.append(track["id"])
	return ids

func get_music_mode_options() -> Array:
	return [MUSIC_MODE_OFF, MUSIC_MODE_LOOP_ONE, MUSIC_MODE_LOOP_ALL, MUSIC_MODE_SHUFFLE]

func get_music_mode_label(mode: String) -> String:
	match mode:
		MUSIC_MODE_OFF:
			return "Off"
		MUSIC_MODE_LOOP_ONE:
			return "Loop One"
		MUSIC_MODE_LOOP_ALL:
			return "Loop All"
		MUSIC_MODE_SHUFFLE:
			return "Shuffle"
		_:
			return "Loop All"

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Master") == -1:
		AudioServer.add_bus(0)
		AudioServer.set_bus_name(0, "Master")
	_ensure_bus("SFX")
	_ensure_bus(HIT_SFX_BUS)
	_ensure_bus("Music")

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus(AudioServer.get_bus_count())
	var bus_index = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")
	if bus_name == HIT_SFX_BUS:
		AudioServer.set_bus_volume_db(bus_index, SFX_HIT_REDUCED_DB)

func _init_sfx_players() -> void:
	for i in range(SFX_PLAYER_COUNT):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = 0.0
		add_child(player)
		sfx_players.append(player)

func _init_music_players() -> void:
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = MUSIC_SILENT_DB
		player.finished.connect(func(): _on_music_player_finished(player))
		add_child(player)
		music_players.append(player)

func _load_sfx_streams() -> void:
	sfx_streams = {
		"hit_brick": load(SFX_DIR + "/hit_brick.mp3"),
		"hit_paddle": load(SFX_DIR + "/hit_paddle.mp3"),
		"hit_wall": load(SFX_DIR + "/hit_wall.mp3"),
		"power_up": load(SFX_DIR + "/power_up.mp3"),
		"power_down": load(SFX_DIR + "/power_down.mp3"),
		"life_lost": load(SFX_DIR + "/life_lost.mp3"),
		"level_complete": load(SFX_DIR + "/level_complete.mp3"),
		"game_over": load(SFX_DIR + "/game_over.mp3"),
		"combo_milestone": load(SFX_DIR + "/combo_milestone.mp3")
	}
	var sfx_keys = sfx_streams.keys()
	for sfx_name in sfx_keys:
		if sfx_streams[sfx_name] == null:
			push_warning("Missing SFX stream asset: " + sfx_name)
			sfx_streams.erase(sfx_name)

func _load_music_tracks() -> void:
	music_tracks.clear()
	var files = _list_music_files()
	if files.is_empty():
		push_warning("No music files found under: " + MUSIC_DIR)
		return
	files.sort()
	for file_name in files:
		var path = ""
		if file_name.find(".") == -1:
			for ext in ["mp3", "ogg", "wav"]:
				var candidate = MUSIC_DIR + "/" + file_name + "." + ext
				if ResourceLoader.exists(candidate):
					path = candidate
					break
		else:
			path = MUSIC_DIR + "/" + file_name
		if path == "":
			continue
		var id = path.get_file().get_basename()
		var stream = load(path)
		if stream == null:
			push_warning("Missing music stream asset: " + path)
			continue
		music_tracks.append({
			"id": id,
			"path": path,
			"stream": stream
		})

func _list_music_files() -> Array:
	var files: Array = []
	if ResourceLoader.has_method("list_directory"):
		var resource_files = ResourceLoader.list_directory(MUSIC_DIR)
		if resource_files != null and resource_files.size() > 0:
			files = resource_files
	if files.is_empty():
		var dir = DirAccess.open(MUSIC_DIR)
		if dir == null:
			push_warning("Music directory not found: " + MUSIC_DIR)
			return []
		files = dir.get_files()
	var best_by_base: Dictionary = {}
	for file_name in files:
		if file_name.ends_with(".import"):
			file_name = file_name.substr(0, file_name.length() - 7)
		elif file_name.ends_with(".remap"):
			file_name = file_name.substr(0, file_name.length() - 6)
		var ext = ""
		if file_name.ends_with(".mp3"):
			ext = "mp3"
		elif file_name.ends_with(".ogg"):
			ext = "ogg"
		elif file_name.ends_with(".wav"):
			ext = "wav"
		elif file_name.find(".") == -1:
			ext = ""
		else:
			continue
		var base = file_name if ext == "" else file_name.substr(0, file_name.length() - (ext.length() + 1))
		if not best_by_base.has(base):
			best_by_base[base] = ext
			continue
		var current_ext = best_by_base[base]
		if current_ext == "ogg":
			continue
		if ext == "ogg":
			best_by_base[base] = ext
			continue
		if current_ext == "mp3" and ext == "wav":
			continue
		if current_ext == "" and ext != "":
			best_by_base[base] = ext
	var cleaned: Array = []
	for base in best_by_base.keys():
		var ext = best_by_base[base]
		cleaned.append(base if ext == "" else base + "." + ext)
	return cleaned

func _apply_saved_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), SaveManager.get_music_volume())
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), SaveManager.get_sfx_volume())

func _load_saved_music_settings() -> void:
	music_mode = SaveManager.get_music_playback_mode()
	music_track_id = SaveManager.get_music_track_id()
	if music_track_id == "":
		music_track_id = _get_default_track_id()

func _start_music_if_enabled() -> void:
	if music_mode == MUSIC_MODE_OFF:
		_refresh_music_processing_state()
		return
	if music_tracks.is_empty():
		_refresh_music_processing_state()
		return
	var track_index = _get_start_track_index()
	_play_track(track_index, false)

func _get_start_track_index() -> int:
	if music_mode == MUSIC_MODE_LOOP_ONE:
		var track_index = _get_track_index_by_id(music_track_id)
		if track_index != -1:
			return track_index
	if music_mode == MUSIC_MODE_SHUFFLE:
		return randi_range(0, music_tracks.size() - 1)
	return 0

func _play_track(track_index: int, crossfade: bool) -> void:
	if track_index < 0 or track_index >= music_tracks.size():
		return
	var track = music_tracks[track_index]
	var new_player_index = 1 - current_player_index
	var new_player = music_players[new_player_index]
	var old_player = _get_current_music_player()

	var stream = track["stream"]
	if stream == null:
		push_warning("Missing stream for track: " + track["id"])
		return
	stream.loop = (music_mode == MUSIC_MODE_LOOP_ONE)
	new_player.stream = stream
	new_player.volume_db = MUSIC_SILENT_DB
	new_player.play()

	current_track_index = track_index
	current_player_index = new_player_index
	is_crossfading = crossfade
	music_paused = false
	paused_player_index = -1
	paused_position = 0.0

	if crossfade and old_player != null and old_player.playing:
		var tween = create_tween()
		tween.tween_property(new_player, "volume_db", 0.0, MUSIC_CROSSFADE_SECONDS)
		tween.tween_property(old_player, "volume_db", MUSIC_SILENT_DB, MUSIC_CROSSFADE_SECONDS)
		tween.finished.connect(func(): _finish_crossfade(old_player))
	else:
		if crossfade:
			new_player.volume_db = MUSIC_SILENT_DB
			var tween = create_tween()
			tween.tween_property(new_player, "volume_db", 0.0, MUSIC_CROSSFADE_SECONDS)
		else:
			new_player.volume_db = 0.0
		if old_player != null:
			old_player.stop()
			old_player.volume_db = MUSIC_SILENT_DB
		is_crossfading = false
	_refresh_music_processing_state()

func _play_next_track() -> void:
	if music_mode == MUSIC_MODE_OFF:
		_show_toast("Music: Off")
		return
	if music_tracks.is_empty():
		_show_toast("Music: No tracks")
		return
	if current_track_index == -1:
		_start_music_if_enabled()
		return
	var next_index = _get_manual_next_track_index()
	if next_index == -1:
		return
	_play_track(next_index, true)
	_save_selected_track(next_index)
	_show_toast("Track: " + music_tracks[next_index]["id"])

func _play_previous_track() -> void:
	if music_mode == MUSIC_MODE_OFF:
		_show_toast("Music: Off")
		return
	if music_tracks.is_empty():
		_show_toast("Music: No tracks")
		return
	if current_track_index == -1:
		_start_music_if_enabled()
		return
	var prev_index = _get_manual_previous_track_index()
	_play_track(prev_index, true)
	_save_selected_track(prev_index)
	_show_toast("Track: " + music_tracks[prev_index]["id"])

func _start_crossfade_to_next_track() -> void:
	if music_tracks.size() <= 1:
		return
	var next_index = _get_next_track_index()
	if next_index == -1:
		return
	_play_track(next_index, true)

func _get_next_track_index() -> int:
	if music_mode == MUSIC_MODE_SHUFFLE:
		if music_tracks.size() <= 1:
			return current_track_index
		var next_index = current_track_index
		while next_index == current_track_index:
			next_index = randi_range(0, music_tracks.size() - 1)
		return next_index
	if music_mode == MUSIC_MODE_LOOP_ALL:
		return (current_track_index + 1) % music_tracks.size()
	if music_mode == MUSIC_MODE_LOOP_ONE:
		return current_track_index
	return -1

func _get_previous_track_index() -> int:
	if music_tracks.size() <= 1:
		return current_track_index
	if music_mode == MUSIC_MODE_SHUFFLE:
		var prev_index = current_track_index
		while prev_index == current_track_index:
			prev_index = randi_range(0, music_tracks.size() - 1)
		return prev_index
	return (current_track_index - 1 + music_tracks.size()) % music_tracks.size()

func _get_manual_next_track_index() -> int:
	if music_tracks.size() <= 1:
		return current_track_index
	if music_mode == MUSIC_MODE_SHUFFLE:
		var next_index = current_track_index
		while next_index == current_track_index:
			next_index = randi_range(0, music_tracks.size() - 1)
		return next_index
	return (current_track_index + 1) % music_tracks.size()

func _get_manual_previous_track_index() -> int:
	if music_tracks.size() <= 1:
		return current_track_index
	if music_mode == MUSIC_MODE_SHUFFLE:
		var prev_index = current_track_index
		while prev_index == current_track_index:
			prev_index = randi_range(0, music_tracks.size() - 1)
		return prev_index
	return (current_track_index - 1 + music_tracks.size()) % music_tracks.size()

func _on_music_player_finished(player: AudioStreamPlayer) -> void:
	if music_mode == MUSIC_MODE_OFF:
		return
	if is_crossfading:
		return
	if player != _get_current_music_player():
		return
	var next_index = _get_next_track_index()
	if next_index == -1:
		return
	_play_track(next_index, true)

func _finish_crossfade(old_player: AudioStreamPlayer) -> void:
	if old_player != null:
		old_player.stop()
		old_player.volume_db = MUSIC_SILENT_DB
	is_crossfading = false
	_refresh_music_processing_state()

func _fade_out_and_stop_music() -> void:
	if music_players.is_empty():
		return
	for player in music_players:
		if not player.playing:
			player.volume_db = MUSIC_SILENT_DB
			continue
		var tween = create_tween()
		tween.tween_property(player, "volume_db", MUSIC_SILENT_DB, MUSIC_CROSSFADE_SECONDS)
		tween.finished.connect(func(): player.stop())
	music_paused = false
	paused_player_index = -1
	paused_position = 0.0
	_refresh_music_processing_state()

func _is_any_music_playing() -> bool:
	for player in music_players:
		if player.playing:
			return true
	return false

func _get_default_track_id() -> String:
	if music_tracks.is_empty():
		return ""
	return music_tracks[0]["id"]

func _get_track_index_by_id(track_id: String) -> int:
	for i in music_tracks.size():
		if music_tracks[i]["id"] == track_id:
			return i
	return -1

func _get_current_music_player() -> AudioStreamPlayer:
	if music_players.is_empty():
		return null
	return music_players[current_player_index]

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]

func _adjust_music_volume(delta_db: float) -> void:
	var new_volume = clampf(SaveManager.get_music_volume() + delta_db, VOLUME_MIN_DB, VOLUME_MAX_DB)
	SaveManager.save_audio_settings(new_volume, SaveManager.get_sfx_volume())
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), new_volume)
	music_volume_changed.emit(new_volume)
	_show_toast("Music Volume: " + str(_volume_to_percent(new_volume)) + "%")

func _toggle_music_pause() -> void:
	if music_mode == MUSIC_MODE_OFF:
		_show_toast("Music: Off")
		return
	if music_paused:
		_resume_music_from_pause()
		return

	var player = _get_current_music_player()
	if player == null or player.stream == null:
		_start_music_if_enabled()
		_show_toast("Music Playing")
		return

	paused_player_index = current_player_index
	paused_position = player.get_playback_position()
	if player.playing:
		player.stream_paused = true
	music_paused = true
	_refresh_music_processing_state()
	_show_toast("Music Paused")

func _resume_music_from_pause() -> void:
	if paused_player_index < 0 or paused_player_index >= music_players.size():
		music_paused = false
		_start_music_if_enabled()
		_show_toast("Music Playing")
		return

	var player = music_players[paused_player_index]
	if player.stream == null and current_track_index != -1:
		player.stream = music_tracks[current_track_index]["stream"]
	if player.stream == null:
		music_paused = false
		_start_music_if_enabled()
		_show_toast("Music Playing")
		return

	player.stream_paused = false
	if not player.playing:
		player.play(paused_position)
	music_paused = false
	_refresh_music_processing_state()
	_show_toast("Music Playing")

func _refresh_music_processing_state() -> void:
	var mode_requires_monitoring = music_mode == MUSIC_MODE_LOOP_ALL or music_mode == MUSIC_MODE_SHUFFLE
	var should_process = mode_requires_monitoring and not music_paused and not is_crossfading and _is_any_music_playing()
	set_process(should_process)

func _volume_to_percent(db_value: float) -> int:
	return int((db_value - VOLUME_MIN_DB) / (VOLUME_MAX_DB - VOLUME_MIN_DB) * 100.0)

func _save_selected_track(track_index: int) -> void:
	if track_index < 0 or track_index >= music_tracks.size():
		return
	SaveManager.save_music_track_id(music_tracks[track_index]["id"])

func _init_toast_ui() -> void:
	var toast_instance = AUDIO_TOAST_SCRIPT.new()
	if toast_instance is Node:
		toast_ui = toast_instance
		add_child(toast_ui)

func _show_toast(text: String) -> void:
	if toast_ui == null or not toast_ui.has_method("show_toast"):
		return
	toast_ui.call("show_toast", text)
