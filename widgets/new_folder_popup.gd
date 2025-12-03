extends Panel

@onready var folder_name = self.find_child("FolderNameLineEdit")

signal folder_name_confirmed(folder_name)

func _on_cancel_button_down() -> void:
    self.hide()


func _on_confirm_button_down() -> void:
    if not folder_name.text.is_empty():
        self.emit_signal("folder_name_confirmed", folder_name.text)
        folder_name.text = ""
        self.hide()


func _on_folder_name_line_edit_text_submitted(new_text: String) -> void:
    _on_confirm_button_down()
