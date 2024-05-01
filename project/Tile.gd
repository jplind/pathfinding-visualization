extends Area2D

@onready var color_rect = $ColorRect
var tween : Tween
var time_step : float = 0.01
var pos
enum {EMPTY, WALL, START, END, FRONTIER, REACHED, PATH}
var type : set = set_type
var white = Color(1, 1, 1, 1)
var black = Color(0, 0, 0, 1)
var purple = Color(0.8, 0.1, 0.7, 1)
var yellow = Color(1, 1, 0, 1)
var red = Color(1, 0.4, 0.3, 1)
var blue = Color(0.2, 0.6, 0.9, 1)
var green = Color(0, 0.9, 0.2, 1)

func _ready():
	Events.time_step_changed.connect(set_time_step)

func set_time_step(x : float):
	time_step = x * 0.01

func set_type(value):
	type = value
	match type:
		EMPTY:
			color_rect.color = white
		WALL:
			color_rect.color = black
		START:
			color_rect.color = purple
		END:
			color_rect.color = yellow
		FRONTIER:
			tween_color(red)
		REACHED:
			tween_color(blue)
		PATH:
			tween_color(green)

func tween_color(color):
	tween = create_tween()
	tween.tween_property(color_rect, "color", color, time_step)
	tween.play()
