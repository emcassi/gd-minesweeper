extends Area2D
class_name Tile

@onready var game = $/root/Game
@onready var animator = $AnimatedSprite2D

var is_bomb: bool
var nearby_count: int
var is_pressed = false
var is_flipped = false
var is_flagged = false
var point = { x = 0, y = 0}

func flip(tiles, force = false):
	if force or (is_pressed and not is_flipped):
		if is_flagged: 
			is_flagged = false
			animator.play('default')
			game.set_state(game.STATES.DEFAULT)
		else:
			is_flipped = true
			if is_bomb:
				animator.play('blow')
			else:
				game.safe_spaces -= 1
				animator.play(str(nearby_count))
				if nearby_count == 0:
					flip_neighbors(tiles)
				game.set_state(game.STATES.SAFE)
				
func flip_neighbors(tiles):
	for i in range(-1, 2):
		for j in range(-1, 2):
			var x = point.x + i
			var y = point.y + j
			if not (x < 0 or x >= game.size or y < 0 or y >= game.size):
				var t: Tile = tiles[{x = x, y = y}]
				if not t.is_flipped:
					t.flip(tiles, true)

func flag():
	if not is_flipped:
		is_flagged = not is_flagged
		
		if is_flagged:
			animator.play('flagged')
		else:
			animator.play('default')
	
func press():
	if not game.game_over:
		if not is_pressed and not is_flipped:
			is_pressed = true
			animator.play('pressed')
			game.set_state(game.STATES.PEEK)
		
func release():
	if not game.game_over:
		is_pressed = false
		if not is_flipped:
			if is_flagged:
				animator.play('flagged')
			else:
				animator.play('default')
			game.set_state(game.STATES.DEFAULT)
		
func count_bombs(bombs):
	var count = 0
	for x in range(-1, 2):
		for y in range(-1, 2):
			for bomb in bombs:
				if bomb.x == point.x + x and bomb.y == point.y + y:
					count += 1
	nearby_count = count
	
func _on_mouse_entered():
	if not game.game_over:
		game.active_tile = self

func _on_mouse_exited():
	if not game.game_over:
		if game.active_tile == self:
			game.active_tile = null
		if not is_flipped:
			release()
