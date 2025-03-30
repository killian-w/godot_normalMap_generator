@tool

extends EditorPlugin

# A class member to hold the dock during the plugin lifecycle
var dock
var icon

func _enter_tree():
	# Initialization of the plugin goes here
	# Load the dock scene and instance it
	dock = preload("res://addons/NormalMap/Normal Map Generator.tscn").instantiate()
	if dock != null:
		# Add the loaded scene to the docks
		add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)
		icon = preload("res://addons/NormalMap/icons/icon.svg") as Texture2D
		if icon != null:
			set_dock_tab_icon(dock, icon)
	else:
		push_error("Failed to instantiate the dock scene.")

func _exit_tree():
	# Clean-up of the plugin goes here
	# Remove the dock if it exists
	if dock != null:
		remove_control_from_docks(dock)
		# Erase the control from memory
		dock.queue_free()
