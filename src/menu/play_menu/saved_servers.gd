extends Node

# Utility for persisting a Dictionary of saved servers to user://saved_servers.save
# Structure stored is a Dictionary keyed by address strings:
# {
#   "127.0.0.1": { "name": "Localhost", "port": 1234 },
#   "example.com:1234": { "name": "Example", "port": 1234 }
# }

const SAVE_PATH: String = "user://saved_servers.save"

# Returns the saved servers Dictionary. If the file doesn't exist or is invalid, returns an empty Dictionary.
func load_saved_servers() -> Dictionary:
	# Use FileAccess static helper to check for file existence
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SavedServers: Failed to open '%s' for reading." % SAVE_PATH)
		return {}

	var data = file.get_var()
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		return {}

	return data

# Internal helper to write the Dictionary to disk. Returns true on success.
func _save_servers(data: Dictionary) -> bool:
	# If the file doesn't exist, create it first so the path is valid.
	if not FileAccess.file_exists(SAVE_PATH):
		var created := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if created == null:
			push_error("SavedServers: Failed to create '%s'." % SAVE_PATH)
			return false
		created.close()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SavedServers: Failed to open '%s' for writing." % SAVE_PATH)
		return false

	file.store_var(data)
	file.close()
	return true

# Adds or overwrites a server entry. Address is used as the key.
# Returns true if the save succeeded.
func add_saved_server(address: String, server_name: String, port: int) -> bool:
	var data: Dictionary = load_saved_servers()
	data[address] = { "name": server_name, "port": int(port) }
	return _save_servers(data)

# Edits an existing server entry. Returns false if the entry does not exist, true on success.
func edit_saved_server(address: String, server_name: String, port: int) -> bool:
	var data: Dictionary = load_saved_servers()
	if not data.has(address):
		return false
	data[address] = { "name": server_name, "port": int(port) }
	return _save_servers(data)

# Removes a server entry by address. Returns false if the entry does not exist, true on success.
func remove_saved_server(address: String) -> bool:
	var data: Dictionary = load_saved_servers()
	if not data.has(address):
		return false
	data.erase(address)
	return _save_servers(data)

# Convenience: return an Array of address keys
func get_saved_server_addresses() -> Array:
	var data: Dictionary = load_saved_servers()
	return data.keys()
