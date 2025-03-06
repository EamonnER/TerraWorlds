using System;
using Godot;
using static TerraWorlds.world.TilesEnum;

namespace TerraWorlds.world;

[GlobalClass]
public partial class WorldGenerator : Node
{
	private int _seed;
	
	private int _worldSize;  // The size of the world in tiles
	private int _mapSize;  // The size of the playable area in tiles
	private int _halfWorldSize;
	private int _caveOffset;
	
	private const int ChunkSize = 32;
	
	private ushort[,] _rawWorld;
	private Chunk[,] _chunks;
	
	public void GenerateWorld(int mapSize, int seed, int caveOffset)
	{
		/*
		 * mapSize should be divisible by ChunkSize
		 */
		
		if (mapSize < ChunkSize || mapSize % ChunkSize != 0)
		{
			throw new Exception("Map size must be a multiple of and at least " + ChunkSize);
		}
		
		_mapSize = mapSize;
		_worldSize = _mapSize / 2;
		_halfWorldSize = _worldSize / 2;
		_caveOffset = caveOffset;
		
		_seed = seed;
		
		_rawWorld = new ushort[_mapSize, _mapSize];
		_drawBlankWorld();
		_drawHeightmap();
		_drawCaves();
		
		_worldToChunks();
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
				else if (distance > _halfWorldSize - _caveOffset)
				{
					_rawWorld[x, y] = (ushort) Dirt;
				}
				else
				{
					_rawWorld[x, y] = (ushort) Stone;
				}
			}
		}
	}
	
	private void _drawHeightmap()
	{
		/*
		 * Carves out the terrain based on perlin noise to create a heightmap.
		 * All 4 sides of the world within the map has this heightmap applied.
		 * Only x value of noise is used for the heightmap for smooth transitions over the world corners.
		 *
		 * It follows the world from the top left, in the right direction, all the way around. This allows the world to
		 * look like a continuous loop, apart from at the top left corner where it meets the start.
		 */
		var noise = new FastNoiseLite();
		noise.Seed = _seed;
		var maxDepth = 35;  // 4 is arbitrary; increase for less depth

		var noiseX = 0;
		var noiseY = 0;
		// Top side
		for (var x = (_mapSize / 2) - _halfWorldSize; x <=  (_mapSize / 2) + _halfWorldSize; x++)
		{
			var noiseValue = Mathf.Abs(noise.GetNoise2D(noiseX, noiseY));
			noiseX++;
			var depth = (int)(noiseValue * maxDepth);
			
			for (var y = (_mapSize / 2) - _halfWorldSize; y < (_mapSize / 2) - _halfWorldSize + depth; y++)
			{
				_rawWorld[x, y] = (ushort) Null;  // Deletes / carves out tile
			}
		}
		// Right side
		for (var y = (_mapSize / 2) - _halfWorldSize; y <=  (_mapSize / 2) + _halfWorldSize; y++)
		{
			var noiseValue = Mathf.Abs(noise.GetNoise2D(noiseX, noiseY));
			noiseY++;
			var depth = (int) (noiseValue * maxDepth);
			
			for (var x = (_mapSize / 2) + _halfWorldSize; x >= (_mapSize / 2) + _halfWorldSize - depth; x--)  // x > -depth because we are carving from right side to left side
			{
				_rawWorld[x, y] = (ushort) Null;
			}
		}
		// Bottom side
		for (var x = (_mapSize / 2) + _halfWorldSize; x >= (_mapSize / 2) - _halfWorldSize; x--)
		{
			var noiseValue = Mathf.Abs(noise.GetNoise2D(noiseX, noiseY));
			noiseX--;
			var depth = (int)(noiseValue * maxDepth);
			
			for (var y = (_mapSize / 2) + _halfWorldSize; y > (_mapSize / 2) + _halfWorldSize - depth; y--)  // Carving upwards
			{
				_rawWorld[x, y] = (ushort) Null;
			}
		}
		// Left side
		for (var y = (_mapSize / 2) + _halfWorldSize; y >= (_mapSize / 2) - _halfWorldSize; y--)
		{
			var noiseValue = Mathf.Abs(noise.GetNoise2D(noiseX, noiseY));
			noiseY--;
			var depth = (int)(noiseValue * maxDepth);
			
			for (var x = (_mapSize / 2) - _halfWorldSize; x < (_mapSize / 2) - _halfWorldSize + depth; x++)
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
		var noise = new FastNoiseLite();
		noise.Seed = _seed;
		
		noise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;
		
		const float caveThreshold = 0.2f;
		
		// Represents the offset needed to reach the cave boundary
		var start = (_mapSize / 2) - _halfWorldSize + _caveOffset;  
		var end = (_mapSize / 2) + _halfWorldSize - _caveOffset;
		for (var x = start; x < end; x++)
		{
			for (var y = start; y < end; y++)
			{
				if (noise.GetNoise2D(x, y) > caveThreshold)
				{
					_rawWorld[x, y] = (ushort) Null;
				}
			}
		}
	}

	private void _worldToChunks()
	{
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
}
