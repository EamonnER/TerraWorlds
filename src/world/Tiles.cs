using System;
using Godot;

namespace TerraWorlds.world;

public enum TilesEnum : ushort
{
	Null = 0,
	Invisible = 1,
	Dirt = 2,
	Grass = 3,
	Stone = 4,
}

[GlobalClass]
public partial class Tiles : RefCounted
{
	// Returns a dictionary that maps each tile's name to its enum value
	public static Godot.Collections.Dictionary<string, int> GetNameToValue()
	{
		var result = new Godot.Collections.Dictionary<string, int>();
		foreach (var tile in Enum.GetValues<TilesEnum>())
		{
			result[tile.ToString()] = (int) tile;
		}
		return result;
	}
}
