# Godot In-Game Mesh Painter

Simple in-game painter that allows to draw on arbitrary meshes.

## Example scene

The project comes with an example scene (`main.tscn`) that includes two meshes that you can paint on (red drawing):

![image](https://github.com/user-attachments/assets/ba74dc7f-76f3-44c8-869e-b65cfa887c2a)

To move the camera, hold and press right mouse button and move your mouse. Use mouse scroll wheel to zoom.

## How to use

Add a `Node` to your scene and assign the `Painter` (`painter.gd`) script to it. To make a meshes paintable, assign it or one of its parents to group "paintable" (the group name can be configured via exported variable `paintable_group` on the `Painter` instance). Those nodes and their children will be searched recursively for `MeshInstance` nodes. All of them will be picked up by the painter and you will be able to drawn on them.

To draw, just click on the mesh :)

## How it works

The `Painter` collects all `MeshInstance`s nodes that are in group `paintable_group` or have a parent that is in `paintable_group`. It parses their `mesh` using `MeshDataTool`. For this to work, it any non-`ArrayMesh` to `ArrayMesh` to be able to initialize the `MeshDataTool`. It also sets the `overlay_material` to an all transparent texture (used to draw on).

Painting is done by a brute-force ray cast. The painter iterates each face of each mesh and performs an `Geometry3D.ray_intersects_triangle()` to detect if the face was clicked. Since it is brute-force, all faces are processed to detect the face that is closest to the camera. If a hitpoint is detected, the corresponding UV coordinate is extracted via barycentric interpolation of the face vertex UVs. It then sets the corresponding pixel of the `overlay_material`'s texture (to red, right now).

## Credits

This project was heavily inspired by [Godot 4 Vertex Painter](https://github.com/bikemurt/godot-vertex-painter) and [In-game Splat Map Texture Painting](https://alfredbaudisch.com/blog/gamedev/godot-engine/godot-engine-in-game-splat-map-texture-painting-dirt-removal-effect/), basically copying their ideas.
