@tool

extends VBoxContainer

var check_button: CheckButton
var dropdown_section

func _ready() -> void:
	check_button = get_child(0).get_child(0)
	dropdown_section = get_child(1)
	dropdown_section.visible = check_button.button_pressed
	check_button.pressed.connect(_check_button_toggled)
	

func _check_button_toggled() -> void:
	dropdown_section.visible = check_button.button_pressed
