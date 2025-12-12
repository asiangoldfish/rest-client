extends Control

#@onready var request_menu_container = self.find_child("RequestMenuContainer")
@onready var requests_list = find_child("Requests")
@onready var request_menu = find_child("RequestOverview") as RequestMenu
@onready var new_folder_popup = find_child("NewFolderPopup")

@onready var request_btn = preload("res://widgets/request_btn.tscn")
@onready var request_folder: PackedScene = preload("res://widgets/request_folder.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    RequestLoader.initialise()
    request_menu.title_was_changed.connect(title_was_changed)
    request_menu.hide()

    load_requests_objects_from_file()

    new_folder_popup.hide()
    new_folder_popup.folder_name_confirmed.connect(folder_name_confirmed)

func _input(event):
    if event.is_action_pressed("quit"):
        get_tree().quit()

    # Save all requests and folders
    if event.is_action_pressed("save_requests"):
        write_requests_to_file()
        print("Request saved")


# Manage saves
# ------------

## Save all requests
##
## This method overrides the save file. Be aware that it will save ALL requests.
func write_requests_to_file():
    var folders = []
    var requests = []

    var json_objects = {}

    # Register folders first
    for child in requests_list.get_children():
        if child is RequestFolder:
            folders.append(child)
        elif child is RequestButton:
            requests.append(child)
        

    for folder in folders:
        var id: String = folder.name
        var display_name: String = folder.title
            
        json_objects.append({
            id: {
                "name": display_name,
                "type": "folder"
            }})
        
        # A folder may be associated with a set of requests. We coulld
        # serialise them here, but to avoid code duplication we do it in a
        # dedicated phase.
        for request in folder.folder_container.get_children():
            if request is RequestButton:
                request.folder_id = id
                requests.append(request)

    for request in requests:
        json_objects[request.request_id] = {
            "name": request.request_name,
            "type": "request",
            "method": request.method,
            "url": request.url,
            "request_body": request.request_body,
            "response_body": request.response_body,
            "folder": request.folder_id,
            "request_headers": request.request_headers,
            "response_headers": request.response_headers
        }

    RequestLoader.write_all_requests(json_objects)

## Read file with all requests and load the requests dynamically
func load_requests_objects_from_file():
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
            var new_folder = request_folder.instantiate()
            requests_list.add_child(new_folder)

            new_folder.title = folder_name
            new_folder.open_context_menu.connect(_open_folder_context_menu)
            new_folders[folder_name] = new_folder

    # 3. Associated requests
    for request_id in RequestLoader.requests:
        var req = RequestLoader.requests.get(request_id)

        assert(req, "Request ID exists, but its meta data is null")

        var new_btn = request_btn.instantiate()
        new_btn.request_id = request_id
        new_btn.read_from_dict(req)
        new_btn.request_was_selected.connect(request_was_selected)

        # If the request is associated with a folder, it will go there.
        var folder_name = req.get("folder")
        if folder_name and not folder_name.is_empty():
            new_folders[folder_name].add_item(new_btn)
        else:
            requests_list.add_child(new_btn)


# Control callbacks
# -----------------

## Create a new and fresh request. Also, associate the request menu with this
## newly created request right away.
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

## Open the new folder menu to enter the new folder name and create it.
func _on_new_folder_button_down() -> void:
    new_folder_popup.show()

    # See folder_name_confirmed() where the folder is created

# Signal Callbacks
# ---------

## Invoked when the user confirms creating a new folder in the new folder menu
func folder_name_confirmed(folder_name: String):
    var new_folder: RequestFolder = request_folder.instantiate()
    const uuid = preload('res://vendor/uuid.gd')
    new_folder.name = uuid.v4()
    requests_list.add_child(new_folder)
    new_folder.title = folder_name

## Invoked when the request menu tries to change a requests name/title
func title_was_changed(request_id: String, new_text: String):
    for child in requests_list.get_children():
        if child.request_id == request_id:
            child.text = new_text

## This is a callback when a request is selected from the requests list
func request_was_selected(request_button: RequestButton):
    request_menu.load_request(request_button)
    request_menu.show()

## Open a request folder's context menu
func _open_folder_context_menu(folder: RequestFolder) -> void:
    print("Open folder: " + folder.folder_name.text)
