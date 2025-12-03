class_name RequestFolder extends FoldableContainer


# ---------------------------------------------
# Drag and drop
# ---------------------------------------------
func _can_drop_data(position, data):
    return data.has("type") and data.type == "button"

func _drop_data(position, data):
    print("Request '" + data.node.request_name + "' moved to folder '" + self.title + "'")
    
    var btn = data.node
    btn.folder = self.title
    btn.get_parent().remove_child(btn)
    self.add_child(btn)
