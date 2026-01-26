using System;
using Godot;
using static TerraWorlds.world.TilesEnum;
using System.IO;
using FileAccess = System.IO.FileAccess;

namespace TerraWorlds.world;

[GlobalClass]
public partial class WorldGenerator : Node
{
	[Signal]
	public delegate void ProgressUpdateEventHandler(string stage, int progress);
	[Signal]
	public delegate void GenCompletedEventHandler();
	[Signal]
	public delegate void LoadCompletedEventHandler();

	private int _worldSize;  // The size of the world in tiles
	private int _mapSize;  // The size of the playable area in tiles
	private int _halfWorldSize;
	private int _caveOffset;
	
	public int Seed { get; set; }

	public int MapSize
	{
		get => _mapSize;
		set
		{
			if (value < ChunkSize || value % ChunkSize != 0)
			{
				throw new Exception("Map size must be a multiple of and at least " + ChunkSize);
			}
			_mapSize = value;
			_worldSize = _mapSize / 2;
			_halfWorldSize = _worldSize / 2;
		}
	}

	public int CaveOffset
	{
		get => _caveOffset;
		set => _caveOffset = value;
	}
	
	private const int ChunkSize = 32;
	
	private ushort[,] _rawWorld;
	private Chunk[,] _chunks;
	
	private String _worldsPath = ProjectSettings.GlobalizePath("user://worlds/");
	
	public void GenerateWorld(string worldName)
	{
		_rawWorld = new ushort[_mapSize, _mapSize];
		_drawBlankWorld();
		_drawHeightmap();
		_drawCaves();
		_addTunnels();
		_drawDirt();
		
		_worldToChunks();
		
		EmitSignal(nameof(ProgressUpdate), "World generation complete!", 100);
		_saveWorldToFile(worldName);
		EmitSignal(nameof(GenCompleted));
	}

	private void _drawBlankWorld()
	{
		/*
		 * World is in the middle of the map area. So there is a padding of 1/4 of the map size around all sides of the
		 * world. This padding area is filled with Null tiles.
		 * Let distance = max(x_distance_from_center_of_world, y_distance_from_center_of_world)
		 * If distance > _halfWorldSize, then the tile is Null.
		 * If _halfWorldSize > distance > _halfWorldSize - _caveOffset, then the tile is Dirt.
		 * If _halfWorldSize - _caveOffset > distance, then the tile is Stone.
		 */
		EmitSignal(nameof(ProgressUpdate), "Generating blank world...", 0);

		var centerOfMap = _mapSize / 2;
		for (var x = 0; x < _mapSize; x++)
		{
			for (var y = 0; y < _mapSize; y++)
			{
				var distance = Mathf.Max(Mathf.Abs(centerOfMap - x), Mathf.Abs(centerOfMap - y));
				if (distance > _halfWorldSize)
				{
					_rawWorld[x, y] = (ushort) Null;
				}
				else
				{
					_rawWorld[x, y] = (ushort) Stone;
				}
				// else if (distance > _halfWorldSize - _caveOffset)
				// {
				// 	_rawWorld[x, y] = (ushort) Dirt;
				// }
				// else
				// {
				// 	_rawWorld[x, y] = (ushort) Stone;
				// }
			}
		}
	}
	
	private void _drawHeightmap()
	{
		/*
		 * Carves out the terrain based on perlin noise to create a heightmap.
		 * All 4 sides of the world within the map has this heightmap applied.
		 *
		 * It follows the world from the top left, in the right direction, all the way around. This allows the world to
		 * look like a continuous loop.
		 */
		EmitSignal(nameof(ProgressUpdate), "Generating heightmap...", 25);
		
		var noise = new FastNoiseLite();
		noise.SetSeed(Seed);
		noise.NoiseType = FastNoiseLite.NoiseTypeEnum.Perlin;
		
		var closeSideOfWorld = (_mapSize / 2) - _halfWorldSize;  // Represents either the top or left side of the world
		var farSideOfWorld = (_mapSize / 2) + _halfWorldSize;  // Represents either the bottom or right side of the world
		
		const int maxDepth = 35;

		var noiseX = 0;
		var noiseY = 0;
		// Top side
		for (var x = closeSideOfWorld; x <=  farSideOfWorld; x++)
		{
			var noiseValue = Mathf.Abs(noise.GetNoise2D(noiseX, noiseY));
			noiseX++;
			var depth = (int)(noiseValue * maxDepth);
			
			for (var y = closeSideOfWorld; y < closeSideOfWorld + depth; y++)
			{
				_rawWorld[x, y] = (ushort) Null;  // Deletes / carves out tile
			}
		}
		// Right side
		for (var y = closeSideOfWorld; y <=  farSideOfWorld; y++)
		{
			var noiseValue = Mathf.Abs(noise.GetNoise2D(noiseX, noiseY));
			noiseY++;
			var depth = (int) (noiseValue * maxDepth);
			
			for (var x = farSideOfWorld; x >= farSideOfWorld - depth; x--)
			{
				_rawWorld[x, y] = (ushort) Null;
			}
		}
		// Bottom side
		for (var x = farSideOfWorld; x >= closeSideOfWorld; x--)
		{
			var noiseValue = Mathf.Abs(noise.GetNoise2D(noiseX, noiseY));
			noiseX--;
			var depth = (int)(noiseValue * maxDepth);
			
			for (var y = farSideOfWorld; y > farSideOfWorld - depth; y--)  // Carving upwards
			{
				_rawWorld[x, y] = (ushort) Null;
			}
		}
		// Left side
		for (var y = farSideOfWorld; y >= closeSideOfWorld; y--)
		{
			var noiseValue = Mathf.Abs(noise.GetNoise2D(noiseX, noiseY));
			noiseY--;
			var depth = (int)(noiseValue * maxDepth);
			
			for (var x = closeSideOfWorld; x < closeSideOfWorld + depth; x++)
			{
				_rawWorld[x, y] = (ushort) Null;
			}
		}
	}

	private void _drawCaves()
	{
		/*
		 * World is in the middle of the map area. So there is a padding of 1/4 of the map size around all sides of the
		 * world. This padding area is filled with Null tiles.
		 * Let distance = max(x_distance_from_center_of_world, y_distance_from_center_of_world)
		 * If _halfWorldSize - _caveOffset > distance, then the tile is eligible to be a cave tile.
		 */
		EmitSignal(nameof(ProgressUpdate), "Generating caves...", 50);
		
		var noise = new FastNoiseLite();
		noise.SetSeed(Seed);
		noise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;
		
		var closeSideOfWorld = (_mapSize / 2) - _halfWorldSize;  
		var farSideOfWorld = (_mapSize / 2) + _halfWorldSize;  
		var centerOfWorld = _mapSize / 2;  

		var start = closeSideOfWorld + _caveOffset;
		var end = farSideOfWorld - _caveOffset;

		const float maxCaveThreshold = 1.0f;
		const float minCaveThreshold = -0f;

		// Calculate the maximum possible distance from the centre
		var maxDistance = Mathf.Sqrt(Mathf.Pow(_halfWorldSize, 2) * 2);

		for (var x = start; x <= end; x++)
		{
			for (var y = start; y <= end; y++)
			{
				var distanceToCenter = Mathf.Sqrt(Mathf.Pow(x - centerOfWorld, 2) + Mathf.Pow(y - centerOfWorld, 2));

				// Inverse linear interpolation for threshold
				var t = distanceToCenter / maxDistance;
				var caveThreshold = Mathf.Lerp(minCaveThreshold, maxCaveThreshold, t);

				if (noise.GetNoise2D(x, y) > caveThreshold)
				{
					_rawWorld[x, y] = (ushort)Null;
				}
			}
		}

	}

	private void _addTunnels()
	{
		EmitSignal(nameof(ProgressUpdate), "Generating tunnels...", 75);
		
		var noise = new FastNoiseLite();
		noise.SetSeed(Seed);
		noise.NoiseType = FastNoiseLite.NoiseTypeEnum.Perlin;
		noise.SetFrequency(0.0025f);
		
		var closeSideOfWorld = (_mapSize / 2) - _halfWorldSize;  // Represents either the top or left side of the world
		var farSideOfWorld = (_mapSize / 2) + _halfWorldSize;  // Represents either the bottom or right side of the world
		
		var boundary = _worldSize / 4;
		
		const float maxUpperBound = 0.10f;
		const float lowerBound = 0f;
		
		for (var x = closeSideOfWorld; x <= farSideOfWorld; x++)
		{
			for (var y = closeSideOfWorld; y <= farSideOfWorld; y++)
			{
				var distanceFromSurface = Mathf.Min(Mathf.Min(x - closeSideOfWorld, farSideOfWorld - x), 
														Mathf.Min(y - closeSideOfWorld, farSideOfWorld - y));
				
				if (distanceFromSurface > boundary) continue;
				
				var upperBound = maxUpperBound;
				
				if (distanceFromSurface > boundary / 2)
				{
					upperBound = Mathf.Lerp(maxUpperBound, lowerBound, 
						(distanceFromSurface-((float) boundary/2)) / ((float) boundary/2));
				}
				
				var noiseValue = noise.GetNoise2D(x, y);
				if ((lowerBound < noiseValue) && noiseValue < upperBound)
				{
					_rawWorld[x, y] = (ushort) Null;
				}
			}
		}
	}

	
	private void _drawDirt()
	{
		/*
		 * Uses noise to turn surface tiles into dirt
		 */
		EmitSignal(nameof(ProgressUpdate), "Generating dirt...", 90);
		
		var closeSideOfWorld = (_mapSize / 2) - _halfWorldSize;  // Represents either the top or left side of the world
		var farSideOfWorld = (_mapSize / 2) + _halfWorldSize;  // Represents either the bottom or right side of the world
		
		const int maxDirtStartDistance = 20;
		const int minDirtStartDistance = 10;

		var noise = new FastNoiseLite();
		noise.SetSeed(Seed);
		noise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;
		
		// Top side
		for (var x = closeSideOfWorld; x <= farSideOfWorld; x++)
		{
			var dirtStartDistance =
				minDirtStartDistance + (minDirtStartDistance *
				                        Mathf.Abs(noise.GetNoise2D(x, closeSideOfWorld + maxDirtStartDistance)));

			var distance = 0;
			var hasReachedSurface = false;
			for (var y = closeSideOfWorld; y <= _mapSize / 2; y++)
			{
				var currentTile = _rawWorld[x, y];
				if (currentTile != (ushort) Null)
				{
					hasReachedSurface = true;
				}
		
				if (!hasReachedSurface) continue;
					
				if (distance < dirtStartDistance && currentTile != (ushort) Null)
				{
					_rawWorld[x, y] = (ushort) Dirt;
				} 
				distance++;
			}
		}
		
		// Right side
		for (var y = closeSideOfWorld; y <= farSideOfWorld; y++)
		{
			var dirtStartDistance =
				minDirtStartDistance + (minDirtStartDistance *
				                        Mathf.Abs(noise.GetNoise2D(farSideOfWorld - maxDirtStartDistance, y)));

			var distance = 0;
			var hasReachedSurface = false;
			for (var x = farSideOfWorld; x >= _mapSize / 2; x--)
			{
				var currentTile = _rawWorld[x, y];
				if (currentTile != (ushort) Null)
				{
					hasReachedSurface = true;
				}
		
				if (!hasReachedSurface) continue;
					
				if (distance < dirtStartDistance && currentTile != (ushort) Null)
				{
					_rawWorld[x, y] = (ushort) Dirt;
				} 
				distance++;
			}
		}
		
		// Bottom side
		for (var x = farSideOfWorld; x >= closeSideOfWorld; x--)
		{
			var dirtStartDistance =
				minDirtStartDistance + (minDirtStartDistance *
				                        Mathf.Abs(noise.GetNoise2D(x, farSideOfWorld - maxDirtStartDistance)));

			var distance = 0;
			var hasReachedSurface = false;
			for (var y = farSideOfWorld; y >= _mapSize / 2; y--)
			{
				var currentTile = _rawWorld[x, y];
				if (currentTile != (ushort) Null)
				{
					hasReachedSurface = true;
				}
		
				if (!hasReachedSurface) continue;
					
				if (distance < dirtStartDistance && currentTile != (ushort) Null)
				{
					_rawWorld[x, y] = (ushort) Dirt;
				} 
				distance++;
			}
		}
		
		// Left side
		for (var y = farSideOfWorld; y >= closeSideOfWorld; y--)
		{
			var stoneStartDistance =
				minDirtStartDistance + (minDirtStartDistance *
				                        Mathf.Abs(noise.GetNoise2D(farSideOfWorld + maxDirtStartDistance, y)));

			var distance = 0;
			var hasReachedSurface = false;
			for (var x = closeSideOfWorld; x <= _mapSize / 2; x++)
			{
				var currentTile = _rawWorld[x, y];
				if (currentTile != (ushort) Null)
				{
					hasReachedSurface = true;
				}
		
				if (!hasReachedSurface) continue;
					
				if (distance < stoneStartDistance && currentTile != (ushort) Null)
				{
					_rawWorld[x, y] = (ushort) Dirt;
				} 
				distance++;
			}
		}
	}

	private void _worldToChunks()
	{
		EmitSignal(nameof(ProgressUpdate), "Converting world to chunks...", 95);
		
		_chunks = new Chunk[_mapSize / ChunkSize, _mapSize / ChunkSize];
		for (var x = 0; x < _mapSize/ChunkSize; x ++)
		{
			for (var y = 0; y < _mapSize/ChunkSize; y ++)
			{
				var chunk = new Chunk();
				chunk.Tiles = new ushort[ChunkSize, ChunkSize];
				for (var i = 0; i < ChunkSize; i++)
				{
					for (var j = 0; j < ChunkSize; j++)
					{
						chunk.Tiles[i, j] = _rawWorld[(x*ChunkSize) + i, (y*ChunkSize) + j];
					}
				}
				
				_chunks[x, y] = chunk;
			}
		}
	}
	
	public int GetWorldSize()
	{
		return _worldSize;
	}
	
	public int GetMapSize()
	{
		return _mapSize;
	}

	public Godot.Collections.Dictionary<ushort, Godot.Collections.Array<Vector2>> GetChunk(int x, int y)
	{
		/*
		 * Vectors returned need to be centered around the world. This means that the top left Vector would be
		 * Vector2(-_mapSize / 2, -_mapSize / 2) and the bottom right Vector would be
		 * Vector2(_mapSize / 2, _mapSize / 2).
		 */
		var rawChunk = _chunks[x, y].ToDict();
		var chunkTiles = new Godot.Collections.Dictionary<ushort, Godot.Collections.Array<Vector2>>();
		
		var halfMapSize = _mapSize / 2;
		foreach (var (tile, positions) in rawChunk)
		{
			var newPositions = new Godot.Collections.Array<Vector2>();
			foreach (var position in positions)
			{
				// ReSharper disable twice PossibleLossOfFraction
				newPositions.Add(new Vector2(position.X - (halfMapSize) + (x*ChunkSize), position.Y - (halfMapSize) + (y*ChunkSize)));
			}
			
			chunkTiles[tile] = newPositions;
		}
		return chunkTiles;
	}
	
	public Godot.Collections.Array<Godot.Collections.Dictionary<ushort, Godot.Collections.Array<Vector2>>> GetAllChunks()
	{
		var allChunks = new Godot.Collections.Array<Godot.Collections.Dictionary<ushort, Godot.Collections.Array<Vector2>>>();
		for (var x = 0; x < _mapSize/ChunkSize; x ++)
		{
			for (var y = 0; y < _mapSize/ChunkSize; y ++)
			{
				allChunks.Add(GetChunk(x, y));
			}
		}
		return allChunks;
	}
	
	private void _saveWorldToFile(string filePath)
	{
		if (!Directory.Exists(_worldsPath)) Directory.CreateDirectory(_worldsPath);
		
		var absoluteFilePath = _worldsPath + filePath;

		using var fileStream = new FileStream(absoluteFilePath, FileMode.Create);
		using var binaryWriter = new BinaryWriter(fileStream);
		binaryWriter.Write(_mapSize);
		for (var x = 0; x < _mapSize / ChunkSize; x++)
		{
			for (var y = 0; y < _mapSize / ChunkSize; y++)
			{
				var chunk = _chunks[x, y];
				for (var i = 0; i < ChunkSize; i++)
				{
					for (var j = 0; j < ChunkSize; j++)
					{
						binaryWriter.Write(chunk.Tiles[i, j]);
					}
				}
			}
		}
	}
	
	public void LoadWorld(string worldName)
	{
		var absoluteFilePath = _worldsPath + worldName + ".tworld";
		if (!File.Exists(absoluteFilePath)) throw new FileNotFoundException("The specified file does not exist.", absoluteFilePath);

		using var fileStream = new FileStream(absoluteFilePath, FileMode.Open, FileAccess.Read, FileShare.Read);
		using var binaryReader = new BinaryReader(fileStream);
		_mapSize = binaryReader.ReadInt32();
		_worldSize = _mapSize / 2;
		_halfWorldSize = _worldSize / 2;
			
		_chunks = new Chunk[_mapSize / ChunkSize, _mapSize / ChunkSize];
		
		EmitSignal(nameof(ProgressUpdate), "Loading chunks from file...", 0);
		for (var x = 0; x < _mapSize / ChunkSize; x++)
		{
			for (var y = 0; y < _mapSize / ChunkSize; y++)
			{
				var chunk = new Chunk();
				chunk.Tiles = new ushort[ChunkSize, ChunkSize];
				for (var i = 0; i < ChunkSize; i++)
				{
					for (var j = 0; j < ChunkSize; j++)
					{
						chunk.Tiles[i, j] = binaryReader.ReadUInt16();
					}
				}
				_chunks[x, y] = chunk;
				
				EmitSignal(nameof(ProgressUpdate), "Loading chunks from file...", (int) ((x * _mapSize / ChunkSize + y) / (_mapSize / ChunkSize * _mapSize / ChunkSize) * 100));
			}
		}
		EmitSignal(nameof(ProgressUpdate), "World loaded from file!", 100);
		EmitSignal(nameof(LoadCompleted));
	}
}
