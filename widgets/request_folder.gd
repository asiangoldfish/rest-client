class_name RequestFolder extends Control

@onready var folder_container: Container = self.find_child("FolderContainer")
@onready var folder_name: LineEdit = self.find_child("FolderName")
@onready var arrow_label: Label = self.find_child("ArrowLabel")

# Folder id: super.name

## Emitted whenever the context menu of a folder should be opened.
signal open_context_menu

# If true, show all child requests
@onready var is_expanded: bool = false:
    get:
        return is_expanded
    set(new_value):
        folder_container.visible = new_value
        is_expanded = new_value

        if new_value:
            arrow_label.text = "⌄"
        else:
            arrow_label.text = "⌃"

# Change the name of the folder
@export var title: String = "New title":
    get:
        return title
    set(new_value):
        self.folder_name.text = new_value
        title = new_value

func add_item(node: Control):
    self.folder_container.add_child(node)

# ---------------------------------------------
# Drag and drop
# ---------------------------------------------
# Check whether the dragged Control node can be dropped
func _can_drop_data(_position, data):
    return data.has("type") and data.type == "button"

# Drop the Control node here
func _drop_data(_position, data):
    print("Request '" + data.node.request_name + "' moved to folder '" + self.title + "'")

    var btn = data.node
    btn.folder = self.title
    btn.get_parent().remove_child(btn)
    self.add_item(btn)

# The user clicks to expand or colapse the request folder


func _on_header_container_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                self.is_expanded = !self.is_expanded

func _on_context_menu(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
            open_context_menu.emit(self)


func _on_folder_name_text_changed(new_text: String) -> void:
    title = new_text
