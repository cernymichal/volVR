using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class ActivateTeleportationRay : MonoBehaviour {
    [SerializeField] private GameObject leftTeleportationRay;
    [SerializeField] private GameObject rightTeleportationRay;

    [SerializeField] private InputActionProperty leftActivate;
    [SerializeField] private InputActionProperty rightActivate;

    private void Update() {
        leftTeleportationRay.SetActive(leftActivate.action.ReadValue<float>() > .1f);
        rightTeleportationRay.SetActive(rightActivate.action.ReadValue<float>() > .1f);
    }
}
