extends Button
class_name RequestButton

signal request_was_selected

var request_id: String = ""
var request_name: String = "New request"

func _ready() -> void:
    self.text = request_name
    
    
# ----------------------------------------
# Drag and drop
#
# The button can be dragged and dropped between folders and outside the folder
# in the requests list. Before the user stops the drag, 
# ----------------------------------------
func _get_drag_data(position):
    # Create a semi-transparent preview while dragging
    var preview = duplicate()
    preview.modulate.a = 0.5
    set_drag_preview(preview)
    
    print("Initialise drag")

    return {
        "type": "button",
        "node": self
    }

func set_request_name(s: String) -> void:
    request_name = s
    self.text = s

func _on_button_down() -> void:
    request_was_selected.emit(request_id)
