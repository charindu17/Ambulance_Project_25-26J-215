import joblib
import numpy as np

# Load the trained model once at startup
model = joblib.load("./ml_models/ambulance_model_tuned.js")

FEATURE_ORDER = [
    "avg_speed",
    "max_force",
    "std_force",
    "min_force",
    "avg_jerk",
    "avg_lateral",
    "max_lateral",
]


def predict(features: dict) -> dict:
    """
    Predict the driving state from a window of sensor features.

    Args:
        features (dict): A dictionary with the following keys:
            - avg_speed   : float  — average GPS speed in the window
            - max_force   : float  — max acceleration magnitude
            - std_force   : float  — std dev of acceleration magnitude
            - min_force   : float  — min acceleration magnitude
            - avg_jerk    : float  — average absolute jerk (change in force)
            - avg_lateral : float  — average absolute lateral acceleration
            - max_lateral : float  — max absolute lateral acceleration

    Returns:
        dict:
            - prediction  : str    — predicted label (e.g. "Cruising", "Braking", ...)
            - confidence  : float  — probability of the predicted class (0–1)
            - probabilities: dict  — probability for every class
    """
    # Build feature vector in the correct order
    X = np.array([[features[f] for f in FEATURE_ORDER]])

    label = model.predict(X)[0]
    proba = model.predict_proba(X)[0]
    class_probs = {cls: round(float(p), 4) for cls, p in zip(model.classes_, proba)}

    return {
        "prediction": label,
        "confidence": round(float(max(proba)), 4),
        "probabilities": class_probs,
    }


# ── Quick test ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    sample = {
        "avg_speed":   3.2,
        "max_force":   10.5,
        "std_force":   0.8,
        "min_force":   9.1,
        "avg_jerk":    0.3,
        "avg_lateral": 0.5,
        "max_lateral": 1.2,
    }

    result = predict(sample)
    print("Prediction  :", result["prediction"])
    print("Confidence  :", result["confidence"])
    print("Probabilities:")
    for cls, prob in result["probabilities"].items():
        print(f"  {cls:<12} {prob:.4f}")