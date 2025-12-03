extends Control

#@onready var request_menu_container = self.find_child("RequestMenuContainer")
@onready var requests_list = find_child("Requests")
@onready var request_menu = find_child("RequestOverview") as RequestMenu
@onready var new_folder_popup = find_child("NewFolderPopup")

@onready var request_btn = preload("res://widgets/request_btn.tscn")
@onready var request_folder = preload("res://widgets/request_folder.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    RequestLoader.initialise()
    request_menu.title_was_changed.connect(title_was_changed)
    request_menu.hide()

    create_requests_objects()
    
    new_folder_popup.hide()
    new_folder_popup.folder_name_confirmed.connect(folder_name_confirmed)

func folder_name_confirmed(folder_name: String):
    var new_folder: RequestFolder = request_folder.instantiate()
    new_folder.title = folder_name
    requests_list.add_child(new_folder)

func title_was_changed(request_id: String, new_text: String):
    for child in requests_list.get_children():
        if child.request_id == request_id:
            child.text = new_text

func _input(event):
    if event.is_action_pressed("quit"):
        get_tree().quit()
        

# Create a new and fresh request. Also, associate the request menu with this
# newly created request right away.
func _on_new_request_button_down() -> void:
    request_menu.can_send_request(true)
    var new_btn: RequestButton = request_btn.instantiate()

    # The UUID helps us save and load the correct UUID to file
    const uuid = preload('res://vendor/uuid.gd')
    new_btn.request_id = uuid.v4()

    requests_list.add_child(new_btn)
    request_menu.clear_all()

    # Show the request right away
    self.request_menu.request = new_btn
    self.request_menu.show()

# Read file with all requests and load the requests dynamically
func create_requests_objects():
    # A request may belong to a folder. So, we must create a folder if one does
    # not already exist. It is worth nothing that no two folders with the same
    # name may exist, as they themselves do not have UUIDs. They are identified
    # by their display name only.
    #
    # A folder consists of the following:
    #   1. FoldableContainer
    #   2. VBoxContainer
    #   3. Associated requests
    #
    # The VBoxContainer ensures that the requests (which actually are buttons)
    # do not stack on top of each other.

    var new_folders: Dictionary = {}

    # Find all folders
    for request_id in RequestLoader.requests:
        assert(RequestLoader.requests.get(request_id), "No request ID was found")
        var folder_name = RequestLoader.requests.get(request_id).get("folder")

        if folder_name and not folder_name.is_empty():
            # 1. Foldable Container
            var new_folder = FoldableContainer.new()
            new_folder.title = folder_name
            new_folders[folder_name] = new_folder

            # 2. VBoxContainer
            var new_vbox = VBoxContainer.new()
            new_folder.add_child(new_vbox)
            requests_list.add_child(new_folder)

    # 3. Associated requests
    for request_id in RequestLoader.requests:
        var req = RequestLoader.requests.get(request_id)

        assert(req, "Request ID exists, but its meta data is null")

        var new_btn = request_btn.instantiate()
        new_btn.request_id = request_id
        new_btn.set_request_name(req.name)
        new_btn.request_was_selected.connect(request_was_selected)

        # If the request is associated with a folder, it will go there.
        var folder_name = req.get("folder")
        if folder_name and not folder_name.is_empty():
            new_folders[folder_name].add_child(new_btn)
        else:
            requests_list.add_child(new_btn)

# This is a callback when a request is selected from the requests list
func request_was_selected(request_button: RequestButton):
    print(request_button)
    request_menu.request = request_button
    request_menu.can_send_request(true)
    request_menu.show()

func _on_new_folder_button_down() -> void:
    new_folder_popup.show()
