using System;
using Godot;
using static TerraWorlds.world.TilesEnum;

namespace TerraWorlds.world;

[GlobalClass]
public partial class WorldGenerator : Node
{
	private FastNoiseLite _noise;
    private int _seed;
    
    private int _worldSize;  // The size of the world in tiles
    private int _mapSize;  // The size of the playable area in tiles
    private int _halfWorldSize;
    private int _caveOffset;
    
    private const int ChunkSize = 32;
    
    private ushort[,] _rawWorld;
    public Chunk[] Chunks { get; set; }
    
    public void GenerateWorld(int worldSize, int seed, int caveOffset)
    {
	    if (worldSize % ChunkSize != 0)
	    {
		    throw new Exception("World size must be a multiple of the chunk size: " + ChunkSize);
	    }
	    
	    _noise = new FastNoiseLite();
        _seed = seed;
        _noise.Seed = _seed;
        
        _worldSize = worldSize;
        _mapSize = _worldSize * 4;
        _halfWorldSize = worldSize / 2;
        _caveOffset = caveOffset;
        
        _rawWorld = new ushort[_mapSize, _mapSize];
        _drawBlankWorld();
        //_drawHeightmap();
        _drawCaves();
        
        _worldToChunks();
        GD.Print(Chunks.Length);
        GD.Print(Chunks.GetType());
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
		 * This implementation treats the world as being completely flat, so it iterates over _worldSize * 4.
		 *
		 * It follows the world from the top left, in the right direction, all the way around. This allows the world to
		 * look like a continuous loop, apart from the top left corner.
		 */
		_noise.NoiseType = FastNoiseLite.NoiseTypeEnum.Perlin;
		var maxDepth = _halfWorldSize / 4;  // 4 is arbitrary; increase for less depth

		for (var x = 0; x < _worldSize * 4; x++) // *4 because we are drawing all 4 sides
		{
			var noiseValue = Mathf.Abs(_noise.GetNoise2D(x, 0));
			var depth = (int)(noiseValue * maxDepth);

			// Top side
			if (x <= _worldSize)
			{
				x += (_mapSize / 2) - _halfWorldSize; // Makes x relative to the world, considering the map size
				for (var y = 0; y < depth; y++)
				{
					y += (_mapSize / 2) - _halfWorldSize; // Makes y relative to the world, considering the map size
					_rawWorld[x, y] = (ushort)Null; // Deletes / carves out tile
				}
			}
			// Right side
			else if (x <= _worldSize * 2)
			{
				/*
				 * Since we're treating the world as flat, we need to adjust x back so its relative position to the
				 * world is top left. Think of this as a reset. x needs to represent from 0 to _worldSize.
				 */
				x -= _worldSize; // Reset x
				x += (_mapSize / 2) - _halfWorldSize;

				for (var y = 0; y < depth; y++)
				{
					y += (_mapSize) - _halfWorldSize;
					_rawWorld[-y, x] = (ushort)Null; // Is carving from right to left, so negative y is needed
				}
			}
			// Bottom side
			else if (x <= _worldSize * 3)
			{
				x -= _worldSize * 2; // Reset x
				x += (_mapSize / 2) - _halfWorldSize;
				for (var y = 0; y < depth; y++)
				{
					y += (_mapSize / 2) - _halfWorldSize;
					// This is essentially the same as top side, but the x and y are flipped
					_rawWorld[-x, -y] = (ushort)Null;
				}
			}
			// Left side
			else
			{
				x -= _worldSize * 3; // Reset x
				x += (_mapSize) - _halfWorldSize - x; // Sets x to count upwards from the bottom left of the world
				for (var y = 0; y < depth; y++)
				{
					y += (_mapSize / 2) - _halfWorldSize;
					_rawWorld[y, x] = (ushort)Null;
				}
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
		_noise.NoiseType = FastNoiseLite.NoiseTypeEnum.Simplex;
		
		const float caveThreshold = 0.2f;
		
		// Represents the offset needed to reach the cave boundary
		var start = (_mapSize / 2) - _halfWorldSize + _caveOffset;  
		var end = (_mapSize / 2) + _halfWorldSize - _caveOffset;
		for (var x = start; x < end; x++)
		{
			for (var y = start; y < end; y++)
			{
				if (_noise.GetNoise2D(x, y) > caveThreshold)
				{
					_rawWorld[x, y] = (ushort) Null;
				}
			}
		}
	}

	private void _worldToChunks()
	{
		Chunks = new Chunk[_worldSize / ChunkSize];
		for (var x = 0; x < _worldSize; x += ChunkSize)
		{
			for (var y = 0; y < _worldSize; y += ChunkSize)
			{
				var chunkTiles = new ushort[ChunkSize];
				for (var i = 0; i < ChunkSize; i++)
				{
					for (var j = 0; j < ChunkSize; j++)
					{
						chunkTiles[i + j] = _rawWorld[x + i, y + j];
					}
				}
				var chunk = new Chunk();
				chunk.Tiles = chunkTiles;
			}
		}
	}
}