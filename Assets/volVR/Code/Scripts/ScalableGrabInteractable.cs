using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.Interaction.Toolkit;

public class ScalableGrabInteractable : XRGrabInteractable {
    private GameObject selectingInteractorA = null;
    private GameObject selectingInteractorB = null;
    private bool scaling { get { return selectingInteractorA && selectingInteractorB; } }
    private float distanceOnEnter;
    private Vector3 scaleOnEnter;

    private void Update() {
        if (!scaling)
            return;

        var scaleFactor = Vector3.Distance(selectingInteractorA.transform.position, selectingInteractorB.transform.position) / distanceOnEnter;
        transform.localScale = scaleOnEnter * scaleFactor;

        // Debug.Log($"scaling {transform.localScale}");
    }

    protected override void OnSelectEntered(SelectEnterEventArgs args) {
        base.OnSelectEntered(args);
        // Debug.Log("Select entered");

        var interactorGameObject = args.interactorObject.transform.gameObject;

        if (!selectingInteractorA)
            selectingInteractorA = interactorGameObject;
        else if (!selectingInteractorB)
            selectingInteractorB = interactorGameObject;
        else
            return;

        if (!scaling)
            return;

        distanceOnEnter = Vector3.Distance(selectingInteractorA.transform.position, selectingInteractorB.transform.position);
        scaleOnEnter = transform.localScale;
    }

    protected override void OnSelectExited(SelectExitEventArgs args) {
        base.OnSelectExited(args);
        // Debug.Log("Select exited");

        var interactorGameObject = args.interactorObject.transform.gameObject;

        if (selectingInteractorA == interactorGameObject)
            selectingInteractorA = null;
        else if (selectingInteractorB == interactorGameObject)
            selectingInteractorB = null;
    }
}
