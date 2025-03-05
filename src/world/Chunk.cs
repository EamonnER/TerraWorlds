using System;
using Godot;

namespace TerraWorlds.world;

[GlobalClass]
public partial class Chunk : Node
{
    public ushort[] Tiles { get; set; }
}