extends Node2D

enum STATES {
	DEFAULT,
	PEEK,
	SAFE,
	WIN,
	LOSE,
}

@onready var tile = preload('res://scenes/tile.tscn')
@onready var field = $Field
@onready var timer_label = $Panel/TimerLabel
@onready var button = $Panel/Button

@onready var default_tex = preload('res://sprites/emoji/btn_default.png')
@onready var peek_tex = preload('res://sprites/emoji/btn_peek.png')
@onready var safe_tex = preload('res://sprites/emoji/btn_safe.png')
@onready var win_tex = preload('res://sprites/emoji/btn_win.png')
@onready var dead_tex = preload('res://sprites/emoji/btn_dead.png')

var started = false
var state: STATES = STATES.DEFAULT
var size = 25
var tile_size = 24
var padding = { x = 75, y = 100 }
var active_tile: Tile
var bomb_count = 100
var tiles: Dictionary
var safe_spaces: int
var game_over = false
var timer: float = 0
var max_timer = 10000
var safe_time = 2
var safe_tex_timer: float

func _ready():
	safe_spaces = size * size - bomb_count
	setup_tiles()

func _process(delta):
	if not started:
		if active_tile:
			if Input.is_action_just_pressed('flip'):
				active_tile.press()
				
			if Input.is_action_just_released('flip'):
				start_game()
				active_tile.flip(tiles)
				print(safe_spaces)
				if not active_tile.is_flagged and active_tile.is_flipped:
					if active_tile.is_bomb:
						lose()
					else:
						if safe_spaces <= 0:
							win()
	
	if not game_over and started:
		if timer < max_timer:
			timer += delta
			timer_label.text = str(int(timer))
		
		if state == STATES.PEEK:
			safe_tex_timer -= delta
			if safe_tex_timer <= 0:
				safe_tex_timer = safe_time
				set_state(STATES.DEFAULT)
		
		if active_tile:
			if Input.is_action_just_pressed('flip'):
				active_tile.press()
				
			if Input.is_action_just_released('flip'):
				active_tile.flip(tiles)
				print(safe_spaces)
				if not active_tile.is_flagged and active_tile.is_flipped:
					if active_tile.is_bomb:
						lose()
					else:
						if safe_spaces <= 0:
							win()
			if Input.is_action_just_released('flag'):
				active_tile.flag()
				
func setup_tiles():
	for i in range(0, size):
		for j in range(0, size):
			var new_tile: Tile = tile.instantiate()
			field.add_child(new_tile)
			new_tile.position = Vector2(i * tile_size + padding.x, j * tile_size + padding.y)
			new_tile.point = { x = i, y = j }
			tiles[{x = i, y = j}] = new_tile

func setup_bombs():
	var bombs: Dictionary = {}
	for i in range(0, bomb_count):
		var valid = false
		var x: int
		var y: int
		while not valid:
			valid = true
			x = randi_range(0, size - 1)
			y = randi_range(0, size - 1)
			
			# no bombs near start
			if abs(x - active_tile.point.x) <= 1 and abs(y - active_tile.point.y) <= 1:
				valid = false
				continue
				
			# check for dups
			for j in bombs:
				if j.x == x and j.y == y:
					valid = false
		bombs[{x = x, y = y}] = true
		tiles[{x = x, y = y}].is_bomb = true
	return bombs

func start_game():
	safe_tex_timer = safe_time
	
	var bombs = setup_bombs()
	for t in field.get_children():
		t = t as Tile
		t.count_bombs(bombs)

	
	started = true
	
func win():
	game_over = true
	set_state(STATES.WIN)
	
func lose():
	game_over = true
	set_state(STATES.LOSE)
	
func set_state(s: STATES):
	state = s
	match s:
		STATES.DEFAULT:
			button.icon = default_tex
		STATES.PEEK:
			button.icon = peek_tex
		STATES.SAFE:
			button.icon = safe_tex
		STATES.WIN:
			button.icon = win_tex
		STATES.LOSE:
			button.icon = dead_tex


func _on_button_pressed():
	get_tree().change_scene_to_file('res://scenes/game.tscn')
