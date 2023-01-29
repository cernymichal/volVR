using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class AnimateHandOnInput : MonoBehaviour {
    [SerializeField] private InputActionProperty pinchAction;
    [SerializeField] private InputActionProperty gripAction;

    private Animator animator;

    private void Awake() {
        animator = GetComponent<Animator>();
    }

    private void Update() {
        animator.SetFloat("Trigger", pinchAction.action.ReadValue<float>());
        animator.SetFloat("Grip", gripAction.action.ReadValue<float>());
    }
}
