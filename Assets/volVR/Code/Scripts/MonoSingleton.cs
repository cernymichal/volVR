using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MonoSingleton<T> : MonoBehaviour where T : MonoSingleton<T> {
    public static T Instance { get; private set; }

    protected virtual void Awake() {
        if (Instance == null)
            Instance = (T)this;
        else {
            LogError("Multiple active instances detected.");
            gameObject.SetActive(false);
        }
    }

    private void OnDestroy() {
        Instance = null;
    }

    protected void Log(string message) {
        Debug.Log($"[{typeof(T).Name}] {message}");
    }

    protected void LogWarning(string warning) {
        Debug.LogWarning($"[{typeof(T).Name}] {warning}", this);
    }

    protected void LogError(string error) {
        Debug.LogError($"[{typeof(T).Name}] {error}", this);
    }
}
