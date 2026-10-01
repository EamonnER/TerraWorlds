using System.Collections.Generic;
using Godot;

namespace TerraWorlds.world;

[GlobalClass]
public partial class LightingEngine : Node
{
    private TileMapLayer _foreground;

    private const float AirDecay = 0.04f;
    private const float SolidDecay = 0.18f;

    private readonly Dictionary<Vector2I, float> _pointLights = new();

    public void Initialize(TileMapLayer foreground)
    {
        _foreground = foreground;
    }

    public void AddPointLight(Vector2I position, float intensity)
    {
        _pointLights[position] = intensity;
    }

    public void RemovePointLight(Vector2I position)
    {
        _pointLights.Remove(position);
    }

    public void ClearPointLights()
    {
        _pointLights.Clear();
    }

    public byte[] ComputeLightMap(
        Vector2I regionOrigin, int width, int height, float skyLight)
    {
        var size = width * height;
        var light = new float[size];
        var isSolid = new bool[size];
        var inQueue = new bool[size];

        for (var ly = 0; ly < height; ly++)
        {
            var ty = regionOrigin.Y + ly;
            for (var lx = 0; lx < width; lx++)
            {
                var tx = regionOrigin.X + lx;
                isSolid[ly * width + lx] =
                    _foreground.GetCellTileData(new Vector2I(tx, ty)) != null;
            }
        }

        // Column-scan seeding from all 4 edges
        for (var lx = 0; lx < width; lx++)
        {
            for (var ly = 0; ly < height; ly++)
            {
                var idx = ly * width + lx;
                if (isSolid[idx]) break;
                light[idx] = skyLight;
            }
        }

        for (var lx = 0; lx < width; lx++)
        {
            for (var ly = height - 1; ly >= 0; ly--)
            {
                var idx = ly * width + lx;
                if (isSolid[idx]) break;
                light[idx] = skyLight;
            }
        }

        for (var ly = 0; ly < height; ly++)
        {
            for (var lx = 0; lx < width; lx++)
            {
                var idx = ly * width + lx;
                if (isSolid[idx]) break;
                light[idx] = skyLight;
            }
        }

        for (var ly = 0; ly < height; ly++)
        {
            for (var lx = width - 1; lx >= 0; lx--)
            {
                var idx = ly * width + lx;
                if (isSolid[idx]) break;
                light[idx] = skyLight;
            }
        }

        // Seed point light sources within the region
        foreach (var (pos, intensity) in _pointLights)
        {
            var lx = pos.X - regionOrigin.X;
            var ly = pos.Y - regionOrigin.Y;
            if (lx < 0 || lx >= width || ly < 0 || ly >= height) continue;
            var idx = ly * width + lx;
            if (intensity > light[idx])
                light[idx] = intensity;
        }

        // BFS light propagation (SPFA variant)
        var queue = new Queue<int>(size);
        for (var i = 0; i < size; i++)
        {
            if (light[i] > 0f)
            {
                queue.Enqueue(i);
                inQueue[i] = true;
            }
        }

        int[] dx = { 1, -1, 0, 0 };
        int[] dy = { 0, 0, 1, -1 };

        while (queue.Count > 0)
        {
            var idx = queue.Dequeue();
            inQueue[idx] = false;
            var currentLight = light[idx];
            if (currentLight <= 0.01f) continue;

            var cx = idx % width;
            var cy = idx / width;

            for (var d = 0; d < 4; d++)
            {
                var nx = cx + dx[d];
                var ny = cy + dy[d];
                if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

                var nidx = ny * width + nx;
                var decay = isSolid[nidx] ? SolidDecay : AirDecay;
                var newLight = currentLight - decay;
                if (newLight > light[nidx])
                {
                    light[nidx] = newLight;
                    if (!inQueue[nidx])
                    {
                        queue.Enqueue(nidx);
                        inQueue[nidx] = true;
                    }
                }
            }
        }

        // Convert to RGBA byte array with night tint
        var nightFactor = Mathf.Clamp(1f - skyLight, 0f, 1f);
        var rTint = 15f * nightFactor;
        var gTint = 15f * nightFactor;
        var bTint = 40f * nightFactor;

        var data = new byte[size * 4];
        for (var i = 0; i < size; i++)
        {
            var darkness = Mathf.Clamp(1f - light[i], 0f, 1f);
            var offset = i * 4;
            data[offset]     = (byte)(rTint * darkness);
            data[offset + 1] = (byte)(gTint * darkness);
            data[offset + 2] = (byte)(bTint * darkness);
            data[offset + 3] = (byte)(darkness * 255f);
        }

        return data;
    }
}
