using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VolumeCutter : MonoBehaviour {
    private GameObject cutterPlane = null;

    private new MeshRenderer renderer;

    private void Awake() {
        renderer = GetComponent<MeshRenderer>();
    }

    private void Update() {
        if (!cutterPlane)
            return;

        WriteRendererProps();
    }

    private void OnTriggerEnter(Collider other) {
        if (other.gameObject.CompareTag("Cutter"))
            cutterPlane = other.gameObject;
    }

    private void OnTriggerExit(Collider other) {
        if (other.gameObject == cutterPlane) {
            cutterPlane = null;
            WriteRendererProps();
        }
    }

    private void WriteRendererProps() {
        MaterialPropertyBlock props = new MaterialPropertyBlock();

        var cutterPosition = cutterPlane ? cutterPlane.transform.position : Vector3.zero;
        var cutterNormal = cutterPlane ? cutterPlane.transform.up.normalized : Vector3.zero;

        props.SetVector("_CutterPosition", new Vector4(cutterPosition.x, cutterPosition.y, cutterPosition.z, cutterPlane ? 1 : 0));
        props.SetVector("_CutterNormal", new Vector4(cutterNormal.x, cutterNormal.y, cutterNormal.z, 0));

        renderer.SetPropertyBlock(props);
    }
}
