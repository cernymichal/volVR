using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;


public class ConvertTIFFLayersToFlipbook : MonoBehaviour {
    [MenuItem("Assets/Convert Layers To Flipbook", true)]
    private static bool NewMenuOptionValidation() {
        return Selection.activeObject is Texture2D; // TODO check for TIFF
    }

    [MenuItem("Assets/Convert Layers To Flipbook")]
    private static void DoSomethingngWithVariable() {
        var original = (Texture2D)Selection.activeObject;
        var filepath = AssetDatabase.GetAssetPath(original);


        Debug.Log(filepath);

        Bitmap bitmap = (Bitmap)Image.FromFile(filepath);

        var sizeX = bitmap.GetFrameCount(FrameDimension.Page);
        var sizeY = bitmap.Size.Width;
        var sizeZ = bitmap.Size.Height;

        TextureFormat format = TextureFormat.R16; // TODO single channel assumed
        TextureWrapMode wrapMode = TextureWrapMode.Clamp;

        var texture = new Texture3D(sizeX, sizeY, sizeZ, format, false);
        texture.wrapMode = wrapMode;

        var pixelData = new ushort[texture.depth * texture.width * texture.height]; // again single channel assumed



        for (int x = 0; x < sizeX; x++) {
            bitmap.SelectActiveFrame(FrameDimension.Page, x);

            MemoryStream byteStream = new MemoryStream();
            bitmap.Save(byteStream, ImageFormat.Tiff);

            var texture2D = new Texture2D(sizeY, sizeZ, format, false);
            texture2D.wrapMode = wrapMode;

            texture2D.LoadRawTextureData(byteStream.ToArray());

            AssetDatabase.CreateAsset(texture2D, $"Assets/{x}.asset");

            // TODO idk dude

            byteStream.Dispose();
        }

        /*
        for (int x = 20; x < sizeX; x++) {
            bitmap.SelectActiveFrame(FrameDimension.Page, x);
            var xOffset = x * texture.width * texture.height;
            for (int y = 0; y < sizeY; y++) {
                var yOffset = y * texture.height;
                for (int z = 0; z < sizeZ; z++) {
                    //pixelData[xOffset + yOffset + z] = bitmap.;
                    //System.Drawing.Color
                    Debug.Log(bitmap.GetPixel(y, z));
                }
                break;
            }
        }
        */

        //texture.SetPixelData<ushort>(pixelData, 0); // SetPixel

        // Apply the changes to the texture and upload the updated texture to the GPU
        //texture.Apply();

        // Save the texture to your Unity Project
        //AssetDatabase.CreateAsset(texture, "Assets/Example3DTexture.asset");
    }


}
