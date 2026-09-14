extends Node

signal steam_lobby_joined(multiplayer_connection_details: Dictionary)
signal steam_lobby_created(lobby_id: int)

var _steam_initialized: bool = false
var _current_lobby_id: int = 0
var _current_host_steam_id: int = 0


func _ready() -> void:
	_initialize_steam()
	_handle_connect_lobby_arg()

func _process(_delta: float) -> void:
	if _steam_initialized:
		Steam.run_callbacks()

func is_steam_ready() -> bool:
	return _steam_initialized


func get_current_lobby_id() -> int:
	return _current_lobby_id


func get_current_host_steam_id() -> int:
	return _current_host_steam_id


# --------------------------------------------------------------------
# Hosting
# --------------------------------------------------------------------

func host_game() -> void:
	if not _steam_initialized:
		print("[SteamManager] host_game ignored: Steam is not initialized")
		return

	_current_lobby_id = 0
	_current_host_steam_id = Steam.getSteamID()

	print("[SteamManager] Creating Steam lobby...")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 8)


func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != 1:
		print("[SteamManager] lobby_created failed: ", result)
		return

	_current_lobby_id = lobby_id

	# The lobby owner is the host.
	Steam.setLobbyData(lobby_id, "host_steam_id", str(_current_host_steam_id))
	Steam.setLobbyData(lobby_id, "game_name", "TerraWorlds")

	print("[SteamManager] Lobby created: ", lobby_id)
	print("[SteamManager] Host SteamID: ", _current_host_steam_id)

	steam_lobby_created.emit(lobby_id)


# --------------------------------------------------------------------
# Joining
# --------------------------------------------------------------------

func join_lobby(lobby_id: int) -> void:
	if not _steam_initialized:
		print("[SteamManager] join_lobby ignored: Steam is not initialized")
		return

	if lobby_id == 0:
		print("[SteamManager] join_lobby ignored: invalid lobby ID")
		return

	print("[SteamManager] Joining lobby: ", lobby_id)
	Steam.joinLobby(lobby_id)


func _on_lobby_joined(
		lobby_data: Variant,
		_permissions: int = 0,
		_locked: bool = false,
		response: int = 0
) -> void:

	var lobby_id: int = 0

	if lobby_data is Dictionary:
		lobby_id = int(lobby_data.get("lobby_id", 0))
	else:
		lobby_id = int(lobby_data)

	if not lobby_id:
		print("[SteamManager] lobby_joined: invalid lobby ID")
		return

	if response != 1 and response != 0:
		print("[SteamManager] Failed to join lobby. Response: ", response)
		return

	_current_lobby_id = lobby_id

	var host_steam_id_text := Steam.getLobbyData(
			lobby_id,
			"host_steam_id"
	)
	
	if host_steam_id_text.is_empty():
		print("[SteamManager] Lobby has no host_steam_id")
		return
	
	_current_host_steam_id = int(host_steam_id_text)
	
	print("[SteamManager] Joined lobby: ", lobby_id)
	print("[SteamManager] Host SteamID: ", _current_host_steam_id)
	
	steam_lobby_joined.emit({
		"host_steam_id": _current_host_steam_id,
		"connection_type": GlobalVariables.MULTIPLAYER_CONNECTION_TYPE.STEAM,
	})


# --------------------------------------------------------------------
# Steam launch / invite handling
# --------------------------------------------------------------------

func _handle_connect_lobby_arg() -> void:
	if not _steam_initialized:
		return

	var args := OS.get_cmdline_user_args()

	for i in range(args.size()):
		var arg: String = args[i]

		if arg == "+connect_lobby" and i + 1 < args.size():
			var lobby_id := int(args[i + 1])
			call_deferred("join_lobby", lobby_id)
			return

		if arg.begins_with("+connect_lobby="):
			var lobby_id_text := arg.split("=", false, 1)[1]
			var lobby_id := int(lobby_id_text)

			call_deferred("join_lobby", lobby_id)
			return


func _on_join_requested(a: Variant, b: Variant = null) -> void:
	var lobby_id := _extract_lobby_id(a)

	if lobby_id == 0 and b != null:
		lobby_id = _extract_lobby_id(b)

	if lobby_id == 0:
		print("[SteamManager] join_requested: no lobby ID found")
		return

	print("[SteamManager] Steam requested lobby join: ", lobby_id)
	join_lobby(lobby_id)


func _extract_lobby_id(value: Variant) -> int:
	if value is Dictionary:
		if value.has("lobby"):
			return int(value["lobby"])

		if value.has("lobby_id"):
			return int(value["lobby_id"])

		return 0

	if typeof(value) == TYPE_INT:
		return int(value)

	return 0


# --------------------------------------------------------------------
# Steam initialisation
# --------------------------------------------------------------------

func _initialize_steam() -> void:
	var init_result: Dictionary = Steam.steamInitEx()

	if init_result.get("status", 0) != 0:
		_steam_initialized = false

		print(
				"[SteamManager] Steam unavailable: ",
				init_result.get("verbal", "unknown error")
		)

		return

	_steam_initialized = true

	print("[SteamManager] Steam initialized successfully")
	print("[SteamManager] Steam ID: ", Steam.getSteamID())

	Steam.connect("lobby_created", _on_lobby_created)
	Steam.connect("lobby_joined", _on_lobby_joined)
	Steam.connect("join_requested", _on_join_requested)
