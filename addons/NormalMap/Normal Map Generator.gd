@tool
extends Control

var current_path = "./generated.png"

@onready var light2d_node := $GUI/VBoxContainer/ViewportContainer/Viewport/TextureRect/Light2D
@onready var viewport_container_node := $GUI/VBoxContainer/ViewportContainer
@onready var texture_rect := $ViewportNormal/Normal

@onready var emboss_spinbox := $GUI/VBoxContainer/EmbossDropdown/DropdownSection/EmbossSpinBox
@onready var emboss_slider := $GUI/VBoxContainer/EmbossDropdown/DropdownSection/EmbossSlider

@onready var light_slider := $GUI/VBoxContainer/LightDropdown/DropdownSection/LightAdjustGroup/LightSlider
@onready var light_spinbox := $GUI/VBoxContainer/LightDropdown/DropdownSection/LightAdjustGroup/LightSpinBox

@onready var bump_spinbox := $GUI/VBoxContainer/BumpDropdown/DropdownSection/BumpSpinBox
@onready var bump_slider := $GUI/VBoxContainer/BumpDropdown/DropdownSection/BumpSlider

var distance_texture;

func set_defaults():
	_on_Normal_toggled(false)
		
	_on_light_check_button_toggled(false)
	light_slider.value = 1.0
	light_spinbox.value = 1.0
	light2d_node.color = "fffb00"
	$GUI/VBoxContainer/LightDropdown/DropdownSection/HBoxContainer_ColorPicker/ColorPickerButton.color = "fffb00"
	
	_on_emboss_check_button_toggled(true)
	emboss_slider.value = 0.1
	emboss_spinbox.value = 0.1
	texture_rect.material.set_shader_parameter("emboss_height", 0.1)
	
	_on_bump_check_button_toggled(true)
	bump_slider.value = 0.3
	bump_spinbox.value = 0.3
	texture_rect.material.set_shader_parameter("bump_height", 0.3)
	
	_on_SpinBoxBlur_value_changed(5.0)
		
	_on_SpinBoxDistance_value_changed(60.0)
	
	_on_InvertX_toggled(false)
	_on_InvertY_toggled(false)

func _ready():
	$ViewportDistance.size = $ViewportDistance/Distance.texture.get_size()
	$ViewportDistance/Distance.position = $ViewportDistance.size / 2
	$ViewportDistance.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	distance_texture = $ViewportDistance.get_texture()
	
	texture_rect.material.set_shader_parameter("distanceTex", distance_texture)
	
	$GUI/VBoxContainer/LightDropdown/DropdownSection/HBoxContainer_ColorPicker/ColorPickerButton.color = light2d_node.color
	$GUI/VBoxContainer/ViewportContainer/Viewport/TextureRect.material.set_shader_parameter("normal_texture", $ViewportNormal.get_texture())
	
	if Engine.is_editor_hint():
		$GUI/VBoxContainer/TextureButton.icon = EditorInterface.get_editor_theme().get_icon("Folder", "EditorIcons") as Texture2D
		$GUI/VBoxContainer/Button.icon = EditorInterface.get_editor_theme().get_icon("Save", "EditorIcons") as Texture2D
	
func _on_Normal_toggled(button_pressed):
	$GUI/VBoxContainer/ViewportContainer/Viewport/TextureRect.material.set_shader_parameter("normal_preview", button_pressed)

func _on_Emboss_Height_value_changed(value):
	texture_rect.material.set_shader_parameter("emboss_height", value)
	emboss_spinbox.value = value

func _on_Bump_Height_value_changed(value):
	texture_rect.material.set_shader_parameter("bump_height", value)
	bump_spinbox.value = value


func _on_SpinBoxBlur_value_changed(value):
	texture_rect.material.set_shader_parameter("blur", value)


func _on_SpinBoxDistance_value_changed(value):
	texture_rect.material.set_shader_parameter("bump", value)


func _on_InvertX_toggled(button_pressed):
	texture_rect.material.set_shader_parameter("invertX", button_pressed)


func _on_InvertY_toggled(button_pressed):
	texture_rect.material.set_shader_parameter("invertY", button_pressed)


func _on_Button_pressed():
	$ViewportNormal.size = $ViewportNormal/Normal.texture.get_size()
	$ViewportNormal/Normal.position = $ViewportNormal.size / 2

	var img = $ViewportNormal.get_texture().get_image()
	img.save_png(current_path)
	
	# Display path in a message box
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Save Confirmation"
	dialog.dialog_text = "Normal Map saved to: " + current_path
	dialog.popup_centered()
	dialog.connect("confirmed", dialog.queue_free)

func _on_TextureButton_pressed():
	# Make the file dialog half the size of the Godot editor and make it popup in the center.
	$FileDialog.size = get_tree().root.size / 2;
	$FileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	$FileDialog.filters = ["*.png ; PNG Images", "*.jpg ; JPEG Images", "*.jpeg ; JPEG Images"]
	$FileDialog.popup_centered();


func _on_FileDialog_file_selected(path):
	var img = Image.new()
	var err = img.load(path)
	if err != OK:
		push_error("Failed to load image: " + path)
		return
	
	var itex = ImageTexture.create_from_image(img)
	
	var aux = path.rsplit(".", true, 1)
	current_path = aux[0] + "_n.png"
	
	# Create and Load new distance texture
	$ViewportDistance/Distance.texture = itex
	$ViewportDistance.size = $ViewportDistance/Distance.texture.get_size()
	$ViewportDistance/Distance.position = $ViewportDistance.size / 2
	$ViewportDistance.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	texture_rect.texture = itex
	$GUI/VBoxContainer/ViewportContainer/Viewport/TextureRect.texture = itex
	$ViewportNormal.size = texture_rect.texture.get_size()
	texture_rect.position = $ViewportNormal.size / 2
	
	distance_texture = $ViewportDistance.get_texture()
	
	$GUI/VBoxContainer/ViewportContainer/Viewport/TextureRect.material.set_shader_parameter("normal_texture", $ViewportNormal.get_texture())
	texture_rect.material.set_shader_parameter("distanceTex", distance_texture)

# Used for tracking the mouse and other input events.
# Currently this is only used to move the Light2D node.
func _input(event):
	if event is InputEventMouseButton and event.pressed == true and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_tree().root.get_mouse_position() # Get mouse position once
		
		# Check if the mouse is inside the ViewportContainer (in local coordinates)
		var local_mouse_pos = viewport_container_node.get_local_mouse_position()
		if viewport_container_node.get_rect().has_point(local_mouse_pos):
			# Convert mouse position to relative coordinates inside the ViewportContainer
			var relative_mouse_pos = local_mouse_pos
			
			# Convert to normalized (0-1) coordinates based on the ViewportContainer size
			var light_pos = relative_mouse_pos / viewport_container_node.size
			
			# Scale to the size of the Viewport (in pixels)
			light_pos *= Vector2($GUI/VBoxContainer/ViewportContainer/Viewport.size)
			
			# Set the light position
			light2d_node.global_position = light_pos

# Changes the Light2D node color based on input from the ColorPickerButton
func _on_ColorPickerButton_color_changed(color):
	light2d_node.color = color

func _on_SpinBox_value_changed(value):
	emboss_slider.value = emboss_spinbox.value


func _on_BumpSpinBox_value_changed(value):
	bump_slider.value = value

func _on_light_spin_box_value_changed(value: float) -> void:
	light2d_node.texture_scale = value
	light_slider.value = value


func _on_light_slider_value_changed(value: float) -> void:
	light2d_node.texture_scale = value
	light_spinbox.value = value


func _on_emboss_check_button_toggled(toggled_on: bool) -> void:
	texture_rect.material.set_shader_parameter("with_emboss", toggled_on)


func _on_bump_check_button_toggled(toggled_on: bool) -> void:
	texture_rect.material.set_shader_parameter("with_distance", toggled_on)


func _on_light_check_button_toggled(toggled_on: bool) -> void:
	light2d_node.enabled = toggled_on
	light2d_node.get_child(0).visible = toggled_on
