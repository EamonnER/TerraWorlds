extends Node

signal steam_join_connect_requested(address: String, port: int)

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

func host_game(host_ip: String = "", port: int = GlobalVariables.DEFAULT_PORT) -> void:
	if not _steam_initialized:
		print("[SteamManager] host_game ignored: Steam is not initialized")
		return

	_current_host_ip = host_ip
	if _current_host_ip.is_empty():
		_current_host_ip = _find_advertise_ip()
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
	print("[SteamManager] Steam initialized successfully")
	Steam.connect("lobby_created", _on_lobby_created)
	Steam.connect("lobby_joined", _on_lobby_joined)
	Steam.connect("join_requested", _on_join_requested)

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != 1:
		print("[SteamManager] lobby_created failed with result=%s" % result)
		return
	
	_current_lobby_id = lobby_id
	Steam.setLobbyData(lobby_id, "connect_ip", _current_host_ip)
	Steam.setLobbyData(lobby_id, "connect_port", str(_current_host_port))
	Steam.setLobbyData(lobby_id, "game_name", "TerraWorlds")
	# Also set the lobby game server entry so clients can get the server info via getLobbyGameServer
	if Engine.has_singleton("Steam"):
		# Some GodotSteam versions expose setLobbyGameServer
		if Steam.has_method("setLobbyGameServer"):
			Steam.setLobbyGameServer(lobby_id, _current_host_ip, _current_host_port, 0)
		else:
			print("[SteamManager] setLobbyGameServer not available in this GodotSteam build")
		
	if _is_private_ip(_current_host_ip):
		_request_public_ip(lobby_id)

func _on_lobby_joined(lobby_data: Variant, _permissions: int = 0, _locked: bool = false, _response: int = 0) -> void:
	if not _joining_from_steam_overlay:
		return

	_joining_from_steam_overlay = false
	var lobby_id: int = 0
	if lobby_data is Dictionary:
		lobby_id = int(lobby_data.get("lobby_id", 0))
	else:
		lobby_id = int(lobby_data)
	if lobby_id == 0:
		return

	var ip: String = Steam.getLobbyData(lobby_id, "connect_ip")
	var port_text: String = Steam.getLobbyData(lobby_id, "connect_port")
	if ip.is_empty() or port_text.is_empty():
		# Try fetching the lobby game server info as a fallback
		if Steam.has_method("getLobbyGameServer"):
			var gs = Steam.getLobbyGameServer(lobby_id)
			if gs.has("ret") and gs["ret"]:
				ip = gs.get("ip", "")
				port_text = str(gs.get("port", ""))
				# fallback successful
			else:
				print("[SteamManager] getLobbyGameServer did not return usable server info")
		else:
			print("[SteamManager] getLobbyGameServer not available in this GodotSteam build")
	
	if ip.is_empty() or port_text.is_empty():
		print("[SteamManager] Still missing lobby metadata after fallback for lobby_id=%s" % lobby_id)
		return

	var port: int = int(port_text)
	emit_signal("steam_join_connect_requested", ip, port)

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

func _on_join_requested(a: Variant, b: Variant = null) -> void:
	# GodotSteam may call this with either (lobby, steam_id) or (steam_id, lobby) or a dictionary; handle all.
	var lobby_id: int = 0
	# If a is a dictionary with 'lobby' key
	if a is Dictionary and a.has("lobby"):
		lobby_id = int(a.get("lobby", 0))
	elif typeof(a) in [TYPE_INT, TYPE_OBJECT] and str(a) != "":
		# a might be numeric lobby id
		lobby_id = int(a)
	# If still zero, try b
	if lobby_id == 0 and b != null:
		if b is Dictionary and b.has("lobby"):
			lobby_id = int(b.get("lobby", 0))
		elif typeof(b) in [TYPE_INT, TYPE_OBJECT] and str(b) != "":
			lobby_id = int(b)

	if lobby_id == 0:
		print("[SteamManager] join_requested: could not resolve a lobby id from payloads")
		return

	connect_to_steam_lobby(lobby_id)

func _find_advertise_ip() -> String:
	var local_addresses: PackedStringArray = IP.get_local_addresses()
	for address in local_addresses:
		if address == "127.0.0.1":
			continue
		if ":" in address:
			continue
		if address.begins_with("169.254."):
			continue
		return address

	return "127.0.0.1"

# Network helpers ---------------------------------------------------------------------------------
func _is_private_ip(ip: String) -> bool:
	if ip is String and ip.length() > 0:
		if ip.begins_with("10."):
			return true
		if ip.begins_with("192.168."):
			return true
		if ip.begins_with("127."):
			return true
		if ip.begins_with("169.254."):
			return true
		if ip.begins_with("172."):
			var parts = ip.split(".")
			if parts.size() >= 2:
				var second = int(parts[1])
				if second >= 16 and second <= 31:
					return true
	return false

func _request_public_ip(lobby_id: int) -> void:
	# Use an HTTPRequest to get the outward-facing IP and update lobby metadata
	var req: HTTPRequest = HTTPRequest.new()
	add_child(req)
	var err = req.request("https://api.ipify.org")
	if err != OK:
		print("[SteamManager] Failed to start public IP request, error=%s" % err)
		req.queue_free()
		return
	# request_completed will be: result, response_code, headers, body
	req.connect("request_completed", Callable(self, "_on_public_ip_request_completed").bind(lobby_id, req))

func _on_public_ip_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, lobby_id: int, req: HTTPRequest) -> void:
	# handle the async HTTPRequest completion; args order: signal args, bound args
	var ip: String = ""
	if response_code == 200:
		ip = body.get_string_from_utf8().strip_edges()
		print("[SteamManager] Public IP detected: %s" % ip)
	else:
		print("[SteamManager] Public IP request failed HTTP code=%s" % response_code)

	# cleanup request node
	if is_instance_valid(req):
		req.queue_free()

	if ip == "" or _is_private_ip(ip):
		print("[SteamManager] Public IP is empty or still private; not updating lobby metadata")
		return

	# Update lobby metadata with public ip
	_current_host_ip = ip
	Steam.setLobbyData(lobby_id, "connect_ip", _current_host_ip)
	Steam.setLobbyData(lobby_id, "connect_port", str(_current_host_port))
	print("[SteamManager] Updated lobby metadata to public ip %s:%s for lobby_id=%s" % [_current_host_ip, _current_host_port, lobby_id])
	if Steam.has_method("setLobbyGameServer"):
		Steam.setLobbyGameServer(lobby_id, _current_host_ip, _current_host_port, 0)
		print("[SteamManager] setLobbyGameServer updated for lobby_id=%s" % lobby_id)
