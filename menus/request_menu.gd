extends Control

class_name RequestMenu

@onready var address_bar = find_child("AddressBar")
@onready var http_request = $HTTPRequest
@onready var response_body = find_child("Response Body")
@onready var request_body = find_child("Request Body")
@onready var response_headers_container = find_child("ResponseHeadersContainer")
@onready var request_headers_container = find_child("RequestHeadersContainer")
@onready var send_request_btn = find_child("SendRequest")
@onready var dummy_address = find_child("DummyAddress")
@onready var title_edit = find_child("TitleEdit")
@onready var method_menu = find_child("MethodMenu")

signal title_was_changed

# The request that the menu is showing
var request: RequestButton = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # HTTP methods dropdown menu
    method_menu.add_item("GET", HTTPClient.Method.METHOD_GET)
    method_menu.add_item("HEAD", HTTPClient.Method.METHOD_HEAD)
    method_menu.add_item("POST", HTTPClient.Method.METHOD_POST)
    method_menu.add_item("PUT", HTTPClient.Method.METHOD_PUT)
    method_menu.add_item("DELETE", HTTPClient.Method.METHOD_DELETE)
    method_menu.add_item("OPTIONS", HTTPClient.Method.METHOD_OPTIONS)
    method_menu.add_item("OPTIONS", HTTPClient.Method.METHOD_TRACE)
    method_menu.add_item("OPTIONS", HTTPClient.Method.METHOD_CONNECT)
    method_menu.add_item("PATCH", HTTPClient.Method.METHOD_PATCH)


    http_request.request_completed.connect(_on_request_completed)

    can_send_request(false)


func can_send_request(check: bool) -> void:
    send_request_btn.disabled = not check
    dummy_address.disabled = not check
    address_bar.editable = check
    response_body.editable = check
    request_body.editable = check
    title_edit.editable = check


# Use this method to clear all inputs and text fields. Useful when switching
# requests.
func clear_all():
    address_bar.text = ""
    response_body.text = ""
    for n in response_headers_container.get_children():
        response_headers_container.remove_child(n)
        n.queue_free()

func _on_address_bar_text_submitted(url: String) -> void:
    if url.is_empty():
        print("Cannot send empty request")
    else:
        var test_headers = [
            "Content-Type: application/json"
        ]

        request.url = url

#        http_request.set_timeout(10000)
        http_request.request(url, test_headers, method_menu.selected, request_body.text)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    # Print headers
    for n in response_headers_container.get_children():
        response_headers_container.remove_child(n)
        n.queue_free()

    for s in headers:
        var new_header = Label.new()
        new_header.text = s
        response_headers_container.add_child(new_header)

    request.response_headers = headers_array_to_dictionary(headers)

    if result == HTTPRequest.RESULT_SUCCESS:
        var text = body.get_string_from_utf8()
        # Attempt to JSONify. If it fails, just output the raw data.

        var json_data = JSON.parse_string(text)

        if json_data != null:
            # Convert the dictionary/array to pretty JSON for display
            response_body.text = JSON.stringify(json_data, "\t")
        else:
            response_body.text = text
        
        print(response_body.text)
        request.response_body = response_body.text
    else:
        print("HTTP request failed with code: ", response_code)


func _on_send_request_button_down() -> void:
    _on_address_bar_text_submitted(address_bar.text)


func _on_dummy_address_button_down() -> void:
    address_bar.text = Constants.mock_request
    request.url = Constants.mock_request


func _on_title_edit_text_submitted(new_text: String) -> void:
    self.request.request_name = new_text
    if not new_text.is_empty():
        self.title_edit.caret_column = new_text.length()
        self.emit_signal("title_was_changed", self.request.request_id, new_text)
    

func load_request(loaded_request: RequestButton):
    can_send_request(true)
    request = loaded_request
    request = loaded_request
    address_bar.text = request.url
    response_body.text = request.response_body
    title_edit.text = request.request_name
    method_menu.selected = get_method_id(request.method)
    request_body.text = request.request_body
    response_body.text = request.response_body

    for key in request.response_headers:
        var new_header = Label.new()
        new_header.text = request.response_headers.get(key)
        response_headers_container.add_child(new_header)

func get_method(method_id: int) -> String:
    var method: String
    if method_id == HTTPClient.Method.METHOD_GET:
        method = "GET"
    elif method_id == HTTPClient.Method.METHOD_POST:
        method = "POST"
    elif method_id == HTTPClient.Method.METHOD_DELETE:
        method = "DELETE"
    elif method_id == HTTPClient.Method.METHOD_PUT:
        method = "PUT"
    elif method_id == HTTPClient.Method.METHOD_PATCH:
        method = "PATCH"
    elif method_id == HTTPClient.Method.METHOD_HEAD:
        method = "HEAD"
    elif method_id == HTTPClient.Method.METHOD_OPTIONS:
        method = "OPTIONS"

    return method

func get_method_id(method: String) -> int:
    var id = 0
    if method == "GET":
        id = HTTPClient.Method.METHOD_GET
    elif method == "POST":
        id = HTTPClient.Method.METHOD_POST
    elif method == "DELETE":
        id = HTTPClient.Method.METHOD_DELETE
    elif method == "PUT":
        id = HTTPClient.Method.METHOD_PUT
    elif method == "PATCH":
        id = HTTPClient.Method.METHOD_PATCH
    elif method == "HEAD":
        id = HTTPClient.Method.METHOD_HEAD
    elif method == "OPTIONS":
        id = HTTPClient.Method.METHOD_OPTIONS

    return id

func get_method_name(method_id: int) -> String:
    match method_id:
        HTTPClient.Method.METHOD_GET:
            return "GET"
        HTTPClient.Method.METHOD_POST:
            return "POST"
        HTTPClient.Method.METHOD_DELETE:
            return "DELETE"
        HTTPClient.Method.METHOD_PUT:
            return "PUT"
        HTTPClient.Method.METHOD_PATCH:
            return "PATCH"
        HTTPClient.Method.METHOD_HEAD:
            return "HEAD"
        HTTPClient.Method.METHOD_OPTIONS:
            return "OPTIONS"
        _:
            return "UNKNOWN"



## Converts HTTP headers in PackedStringArray to dictionary
func headers_array_to_dictionary(headers_array: PackedStringArray) -> Dictionary:
    var headers_dict = {}
    for header_string in headers_array:
        # Split the string at the first occurrence of ": "
        var separator_index = header_string.find(":")
        if separator_index != -1:
            var key = header_string.substr(0, separator_index).strip_edges()
            var value = header_string.substr(separator_index + 1, header_string.length()).strip_edges()
            # If the key already exists, append the value (handling multi-value headers, e.g., Set-Cookie)
            if headers_dict.has(key):
                headers_dict[key] = str(headers_dict[key]) + "; " + value
            else:
                headers_dict[key] = value
    return headers_dict

func _on_method_menu_item_selected(index: int) -> void:
    if not request:
        return

    request.method = get_method_name(index)

func _on_address_bar_text_changed(new_text: String) -> void:
    request.url = new_text
    

func _on_request_body_text_changed() -> void:
    request.request_body = request_body.text