@tool

extends EditorPlugin

# A class member to hold the dock during the plugin lifecycle
var dock
var tab_icon

func _enter_tree():
	# Initialization of the plugin goes here
	# Load the dock scene and instance it
	dock = preload("res://addons/NormalMap/Normal Map Generator.tscn").instantiate()
	tab_icon = preload("res://addons/NormalMap/graphics/tab_icon.svg") as Texture2D
	if dock and tab_icon != null:
		# Add the loaded scene to the docks
		add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)
		set_dock_tab_icon(dock, tab_icon)
		dock.set_defaults()
	else:
		push_error("Failed to instantiate the dock scene.")

func _exit_tree():
	# Clean-up of the plugin goes here
	# Remove the dock if it exists
	if dock != null:
		remove_control_from_docks(dock)
		# Erase the control from memory
		dock.queue_free()
