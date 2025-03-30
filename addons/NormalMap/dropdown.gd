@tool

extends VBoxContainer

@export var label_text: String = "Properties"

var check_button: CheckButton
var label: Label
var dropdown_section: Container

func _ready() -> void:
	check_button = get_child(0).get_child(0)
	label = get_child(0).get_child(1)
	dropdown_section = get_child(1)
	
	dropdown_section.visible = check_button.button_pressed
	label.text = label_text
	check_button.pressed.connect(_check_button_toggled)
	
func _check_button_toggled() -> void:
	dropdown_section.visible = check_button.button_pressed
