extends Node2D

var grid_size = Vector2i(25, 25)
var tile_size = Vector2(20, 20)
var offset = Vector2(1, 1)
var directions = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
var grid
var tile_scene = preload("res://Tile.tscn")

enum {EMPTY, WALL, START, END, FRONTIER, REACHED, PATH}
enum states {FREE, RUNNING, FINISHED}
var is_painting = null
var start = null
var end = null
var state = states.FREE

var cost_so_far = {}

func _ready():
	grid = make_grid()
	Events.search_initiated.connect(start_search)
	Events.reset_initiated.connect(reset_grid)

func start_search(x : int):
	if start and end:
		clear_search()
		Events.search_started.emit()
		match x:
			0:
				breadth_first_search()
			1:
				greedy_search()
			2:
				a_star_search()

func end_search():
	Events.search_ended.emit()

func make_grid():
	var arr = []
	for x in grid_size.x:
		arr.append([])
		for y in grid_size.y:
			var tile =  tile_scene.instantiate()
			arr[x].append(tile)
			tile.position = (tile_size + offset) * Vector2(x, y) + tile_size * 0.5
			add_child(tile)
			tile.pos = Vector2i(x, y)
			tile.connect("input_event", Callable(self, "tile_clicked").bind(tile))
			tile.type = EMPTY
	return arr

func clear_search():
	for tile in get_tree().get_nodes_in_group("tiles"):
		if tile.type == REACHED or tile.type == FRONTIER or tile.type == PATH:
			tile.type = EMPTY
	state = states.FREE

func reset_grid():
	for tile in get_tree().get_nodes_in_group("tiles"):
		tile.type = EMPTY
	state = states.FREE
	start = null
	end = null

func tile_clicked(_viewport, event, _shape_idx, tile):
	if not state == states.FREE:
		return
	if event.is_action_pressed("left_click"):
		if tile.type == EMPTY:
			tile.type = WALL
			is_painting = WALL
		elif tile.type == WALL:
			tile.type = EMPTY
			is_painting = EMPTY
	if is_painting != null:
		if event is InputEventMouseMotion:
			if tile.type == START or tile.type == END:
				return
			if tile.type != is_painting:
				tile.type = is_painting
	if event.is_action_pressed("right_click"):
		match tile.type:
			START:
				tile.type = EMPTY
				start = null
			END:
				tile.type = EMPTY
				end = null
			_:
				if start != null:
					if end == null:
						tile.type = END
						end = tile
				elif start == null:
					tile.type = START
					start = tile

func _input(event):
	match state:
		states.FREE:
			if event.is_action_released("left_click"):
				is_painting = null
		states.RUNNING:
			return
		states.FINISHED:
			if event is InputEventKey:
				if event.keycode == KEY_0:
					clear_search()
			if event.is_action_pressed("space"):
				reset_grid()

func get_neighbors(tile):
	var neighbors = []
	for dir in directions:
		var pos = tile.pos + dir
		if pos.x in range(grid_size.x) and pos.y in range(grid_size.y):
			var neighbor = grid[pos.x][pos.y]
			if neighbor.type != WALL:
				neighbors.append(neighbor)
	return neighbors

func approximate_distance(tile):
	return abs(end.pos.x - tile.pos.x) + abs(end.pos.y - tile.pos.y)

func sort_by_approximate_distance(a, b):
	if approximate_distance(a) < approximate_distance(b):
		return true
	else:
		return false

func sort_by_a_star(a, b):
	if approximate_distance(a) + cost_so_far[a] < approximate_distance(b) + cost_so_far[b]:
		return true
	else:
		return false

func breadth_first_search():
	state = states.RUNNING
	var frontier = [start]
	var came_from = {start : null}
	var path = []
	while not came_from.has(end) and not frontier.is_empty():
		var tile = frontier.pop_front()
		for neighbor in get_neighbors(tile):
			if not came_from.has(neighbor):
				frontier.append(neighbor)
				came_from[neighbor] = tile
				if neighbor.type != START and neighbor.type != END:
					neighbor.type = FRONTIER
					await neighbor.tween.finished
		if tile.type != START and tile.type != END:
			tile.type = REACHED
			await tile.tween.finished
	if not came_from.has(end):
		print("No path!")
	else:
		var current = end
		while came_from[current] != start:
			path.push_front(came_from[current])
			current = came_from[current]
		for tile in path:
			tile.type = PATH
			await tile.tween.finished
	state = states.FINISHED
	end_search()
	print("Area: " + str(came_from.size()) + " tiles, Path: " + str(path.size()) + " tiles")

func greedy_search():
	state = states.RUNNING
	var frontier = [start]
	var came_from = {start : null}
	var path = []
	while not came_from.has(end) and not frontier.is_empty():
		frontier.sort_custom(Callable(self, "sort_by_approximate_distance"))
		var tile = frontier.pop_front()
		for neighbor in get_neighbors(tile):
			if not came_from.has(neighbor):
				frontier.append(neighbor)
				came_from[neighbor] = tile
				if neighbor.type != START and neighbor.type != END:
					neighbor.type = FRONTIER
					await neighbor.tween.finished
		if tile.type != START and tile.type != END:
			tile.type = REACHED
			await tile.tween.finished
	if not came_from.has(end):
		print("No path!")
	else:
		var current = end
		while came_from[current] != start:
			path.push_front(came_from[current])
			current = came_from[current]
		for tile in path:
			tile.type = PATH
			await tile.tween.finished
	state = states.FINISHED
	end_search()
	print("Area: " + str(came_from.size()) + " tiles, Path: " + str(path.size()) + " tiles")

func a_star_search():
	state = states.RUNNING
	var frontier = [start]
	var came_from = {start : null}
	var path = []
	cost_so_far[start] = 0
	while not came_from.has(end) and not frontier.is_empty():
		frontier.sort_custom(Callable(self, "sort_by_a_star"))
		var tile = frontier.pop_front()
		for neighbor in get_neighbors(tile):
			if not came_from.has(neighbor):
				frontier.append(neighbor)
				came_from[neighbor] = tile
				cost_so_far[neighbor] = cost_so_far[tile] + 1
				if neighbor.type != START and neighbor.type != END:
					neighbor.type = FRONTIER
					await neighbor.tween.finished
		if tile.type != START and tile.type != END:
			tile.type = REACHED
			await tile.tween.finished
	if not came_from.has(end):
		print("No path!")
	else:
		var current = end
		while came_from[current] != start:
			path.push_front(came_from[current])
			current = came_from[current]
		for tile in path:
			tile.type = PATH
			await tile.tween.finished
	state = states.FINISHED
	end_search()
	cost_so_far.clear()
	print("Area: " + str(came_from.size()) + " tiles, Path: " + str(path.size()) + " tiles")
