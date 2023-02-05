# volVR

Rendering Unity's 3D texture with a ray marching shader

The object can be naturally manipulated around the scene and cut with a provided plane to view its cross section

<p align="middle">
    <img src=".images/demo.gif" />
</p>

<p align="middle">
    <img src=".images/crosssection.png" />
    <span>the plane (see-through, white when viewed from above) hiding the top half of an MRI scan</span>
</p>

## Controls

- grab objects up close with grip buttons
- teleportation on triggers (preview on light press)
- continuous turn and walk on joysticks

<p align="middle">
    <img src=".images/teleport.png" />
</p>

## Converting stacked TIFF to a flipbook texture

Using imagemagick utilities

```sh
convert source.tiff +adjoin 'layer-%04d.tiff'
montage layer-*.tiff -tile x1 -geometry +0+0 -background black out.tiff
convert out.tiff -colorspace sRGB -type truecolor out-rgb.tiff
```
