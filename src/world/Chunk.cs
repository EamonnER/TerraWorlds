using Godot;

namespace TerraWorlds.world;

[GlobalClass]
public partial class Chunk : Node
{
    public ushort[,] Tiles { get; set; }
    
    // Returns a dictionary that maps the tile ID to a vector2 of the tile's position in the chunk
    public Godot.Collections.Dictionary<ushort, Godot.Collections.Array<Vector2>> ToDict()
    {
        var tilePositions = new Godot.Collections.Dictionary<ushort, Godot.Collections.Array<Vector2>>();
        for (var x = 0; x < Tiles.GetLength(0); x++)
        {
            for (var y = 0; y < Tiles.GetLength(1); y++)
            {
                var tile = Tiles[x, y];
                if (!tilePositions.TryGetValue(tile, out var value))
                {
                    value = [];
                    tilePositions[tile] = value;
                }

                value.Add(new Vector2(x, y));
            }
        }
        return tilePositions;
    }
}