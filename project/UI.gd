extends CanvasLayer

@onready var time_step_slider = %TimeStepSlider
@onready var breadth_first_button = %BreadthFirstButton
@onready var greedy_button = %GreedyButton
@onready var a_star_button = %AStarButton
@onready var reset_button = %ResetButton

func _ready():
	Events.search_started.connect(disable_buttons)
	Events.search_ended.connect(enable_buttons)

func _on_breadth_first_button_pressed():
	Events.search_initiated.emit(0)

func _on_greedy_button_pressed():
	Events.search_initiated.emit(1)

func _on_a_star_button_pressed():
	Events.search_initiated.emit(2)

func _on_reset_button_pressed():
	Events.reset_initiated.emit()

func _on_time_step_slider_drag_ended(value_changed):
	if value_changed:
		Events.time_step_changed.emit(101 - time_step_slider.value)

func disable_buttons():
	breadth_first_button.disabled = true
	greedy_button.disabled = true
	a_star_button.disabled = true
	reset_button.disabled = true

func enable_buttons():
	breadth_first_button.disabled = false
	greedy_button.disabled = false
	a_star_button.disabled = false
	reset_button.disabled = false
