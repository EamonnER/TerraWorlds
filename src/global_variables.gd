extends Node

const TILE_SIZE: int = 16
const CHUNK_SIZE: int = 32

const DEFAULT_PORT: int = 18080

var sky_light_level: float = 1.0

enum MULTIPLAYER_CONNECTION_TYPE {
	NONE = 0,
	STEAM = 1,
	ENET = 2,
} 
