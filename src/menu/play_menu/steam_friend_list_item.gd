extends MarginContainer
class_name SteamFriendListItem

signal just_selected(server: SavedServerListItem)


var steam_id: int
var steam_name: String
var status: String
var lobby_id: int
var avatar: Texture2D


func set_details(new_steam_id: int, new_avatar: Texture2D, new_steam_name: String, new_status: String, new_lobby_id: int) -> void:
	steam_id = new_steam_id
	steam_name = new_steam_name
	status = new_status
	lobby_id = new_lobby_id
	avatar = new_avatar

	$SteamFriendButton.set_text(steam_name)
	if avatar:
		$SteamFriendButton.set_button_icon(avatar)


func set_selected(selected: bool) -> void:
	$SteamFriendButton.button_pressed = selected


func _on_steam_friend_select_button_toggled(toggled_on: bool) -> void:
	if toggled_on: just_selected.emit(self)
