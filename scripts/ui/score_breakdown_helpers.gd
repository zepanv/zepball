class_name ScoreBreakdownHelpers
extends RefCounted

## Shared formatting and challenge-mode helpers used by both
## Level Complete and Set Complete screens.

static func comma_sep(value: int) -> String:
	var s := str(abs(value))
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	if value < 0:
		result = "-" + result
	return result

static func format_bonus(value: int) -> String:
	if value > 0:
		return "+" + comma_sep(value)
	return comma_sep(value)

static func format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes: int = int(floor(float(total_seconds) / 60.0))
	var secs: int = int(total_seconds % 60)
	return "%02d:%02d" % [minutes, secs]

static func get_active_challenge_mode() -> String:
	if MenuController and MenuController.has_method("get_challenge_mode"):
		return str(MenuController.get_challenge_mode())
	return "normal"

static func is_challenge_set_run(challenge_mode: String) -> bool:
	return MenuController.current_play_mode == MenuController.PlayMode.SET and challenge_mode != "normal"

static func get_challenge_mode_label(challenge_mode: String) -> String:
	match challenge_mode:
		"iron_ball":
			return "IRON BALL"
		"one_life":
			return "ONE LIFE"
		"time_attack":
			return "TIME ATTACK"
		_:
			return "NORMAL"
