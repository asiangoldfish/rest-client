extends Button
class_name RequestButton

signal request_was_selected

var request_id: String = ""
var request_name: String = "New request"
var folder_id: String = ""
var method: String = "GET"
var url: String = "localhost"
var request_body: String = ""
var response_body: String = ""

var request_headers: Dictionary = {}
var response_headers: Dictionary = {}


## Given the respective button's entry in the save file, populate its properties
func read_from_dict(dict: Dictionary):
    # Request id must be set by the caller
    request_name = dict.get("name")
    folder_id = dict.get("folder")
    method = dict.get("method")
    url = dict.get("url")
    request_body = dict.get("request_body")
    response_body = dict.get("response_body")
    request_headers = dict.get("request_headers")
    response_headers = dict.get("response_headers")


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
    self.emit_signal("request_was_selected", self)


