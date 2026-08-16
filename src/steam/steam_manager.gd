extends Node

var _steam_initialized: bool = false
var _current_lobby_id: int = 0
var _current_host_ip: String = "127.0.0.1"
var _current_host_port: int = GlobalVariables.DEFAULT_PORT
var _joining_from_steam_overlay: bool = false

func _ready() -> void:
	_initialize_steam()
	_handle_connect_lobby_arg()

func _process(_delta: float) -> void:
	if _steam_initialized:
		Steam.run_callbacks()

func is_steam_ready() -> bool:
	return _steam_initialized

func host_game(host_ip: String = "127.0.0.1", port: int = GlobalVariables.DEFAULT_PORT) -> void:
	if not _steam_initialized:
		return
	
	_current_host_ip = host_ip
	_current_host_port = port
	_current_lobby_id = 0
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 8)

func open_invite_overlay() -> void:
	if not _steam_initialized or _current_lobby_id == 0:
		return
	
	Steam.activateGameOverlayInviteDialog(_current_lobby_id)

func connect_to_steam_lobby(lobby_id: int) -> void:
	if not _steam_initialized or lobby_id == 0:
		return
	
	_joining_from_steam_overlay = true
	Steam.joinLobby(lobby_id)

func _initialize_steam() -> void:
	var init_result: Dictionary = Steam.steamInitEx()
	if init_result.get("status", 0) != 0:
		_steam_initialized = false
		print("Steam is unavailable: %s" % init_result.get("verbal", "unknown error"))
		return
	
	_steam_initialized = true
	Steam.connect("lobby_created", _on_lobby_created)
	Steam.connect("lobby_joined", _on_lobby_joined)
	Steam.connect("join_requested", _on_join_requested)

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != 1:
		return
	
	_current_lobby_id = lobby_id
	Steam.setLobbyData(lobby_id, "connect_ip", _current_host_ip)
	Steam.setLobbyData(lobby_id, "connect_port", str(_current_host_port))
	Steam.setLobbyData(lobby_id, "game_name", "TerraWorlds")

func _on_lobby_joined(lobby_id: int) -> void:
	if not _joining_from_steam_overlay:
		return
	
	_joining_from_steam_overlay = false
	var ip: String = Steam.getLobbyData(lobby_id, "connect_ip")
	var port_text: String = Steam.getLobbyData(lobby_id, "connect_port")
	if ip.is_empty() or port_text.is_empty():
		return
	
	var joined_scene: Node = get_tree().current_scene
	if joined_scene and joined_scene.has_method("connect_to_server"):
		joined_scene.connect_to_server(ip, int(port_text))

func _handle_connect_lobby_arg() -> void:
	if not _steam_initialized:
		return
	
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for i in range(args.size()):
		var arg: String = args[i]
		if arg == "+connect_lobby" and i + 1 < args.size():
			call_deferred("connect_to_steam_lobby", int(args[i + 1]))
			return
		if arg.begins_with("+connect_lobby="):
			var lobby_id_text: String = arg.split("=", false, 1)[1]
			call_deferred("connect_to_steam_lobby", int(lobby_id_text))
			return

func _on_join_requested(friend_id: int, lobby_id: int) -> void:
	connect_to_steam_lobby(lobby_id)
