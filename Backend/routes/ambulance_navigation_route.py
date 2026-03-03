from flask import Blueprint, request, jsonify
import joblib
import numpy as np
import os

# Load model once at startup
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'ambulance_model.pkl')
model = joblib.load(MODEL_PATH)

FEATURE_ORDER = [
    "avg_speed",
    "max_force",
    "std_force",
    "min_force",
    "avg_jerk",
    "avg_lateral",
    "max_lateral",
]

prediction_bp = Blueprint('prediction', __name__, url_prefix='/prediction')


@prediction_bp.route('/predict', methods=['POST'])
def predict():
    """
    Predict driving state from a single window of sensor features.

    Request Body (JSON):
    {
        "avg_speed":   3.2,
        "max_force":   10.5,
        "std_force":   0.8,
        "min_force":   9.1,
        "avg_jerk":    0.3,
        "avg_lateral": 0.5,
        "max_lateral": 1.2
    }

    Response:
    {
        "prediction": "Cruising",
        "confidence": 0.87,
        "probabilities": {
            "Braking": 0.05,
            "Cruising": 0.87,
            "Lane Left": 0.04,
            "Lane Right": 0.04
        }
    }
    """
    try:
        data = request.get_json()

        # Validate all required features are present
        missing = [f for f in FEATURE_ORDER if f not in data]
        if missing:
            return jsonify({'error': f'Missing required features: {missing}'}), 400

        # Build feature vector
        X = np.array([[float(data[f]) for f in FEATURE_ORDER]])

        label = model.predict(X)[0]
        proba = model.predict_proba(X)[0]
        class_probs = {cls: round(float(p), 4) for cls, p in zip(model.classes_, proba)}

        return jsonify({
            'prediction': label,
            'confidence': round(float(max(proba)), 4),
            'probabilities': class_probs
        }), 200

    except (ValueError, TypeError) as e:
        return jsonify({'error': f'Invalid feature value: {str(e)}'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@prediction_bp.route('/predict/batch', methods=['POST'])
def predict_batch():
    """
    Predict driving states for multiple windows at once.

    Request Body (JSON):
    {
        "windows": [
            { "avg_speed": 3.2, "max_force": 10.5, ... },
            { "avg_speed": 5.1, "max_force": 11.2, ... }
        ]
    }

    Response:
    {
        "count": 2,
        "predictions": [
            { "index": 0, "prediction": "Cruising",  "confidence": 0.87, "probabilities": {...} },
            { "index": 1, "prediction": "Braking",   "confidence": 0.91, "probabilities": {...} }
        ]
    }
    """
    try:
        data = request.get_json()

        if 'windows' not in data or not isinstance(data['windows'], list):
            return jsonify({'error': "'windows' must be a list of feature objects"}), 400

        windows = data['windows']
        if len(windows) == 0:
            return jsonify({'error': "'windows' list cannot be empty"}), 400

        # Validate and build matrix
        X_list = []
        for i, window in enumerate(windows):
            missing = [f for f in FEATURE_ORDER if f not in window]
            if missing:
                return jsonify({'error': f'Window {i} is missing features: {missing}'}), 400
            X_list.append([float(window[f]) for f in FEATURE_ORDER])

        X = np.array(X_list)
        labels = model.predict(X)
        probas = model.predict_proba(X)

        predictions = []
        for i, (label, proba) in enumerate(zip(labels, probas)):
            class_probs = {cls: round(float(p), 4) for cls, p in zip(model.classes_, proba)}
            predictions.append({
                'index': i,
                'prediction': label,
                'confidence': round(float(max(proba)), 4),
                'probabilities': class_probs
            })

        return jsonify({
            'count': len(predictions),
            'predictions': predictions
        }), 200

    except (ValueError, TypeError) as e:
        return jsonify({'error': f'Invalid feature value: {str(e)}'}), 400
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@prediction_bp.route('/classes', methods=['GET'])
def get_classes():
    """
    Returns the list of classes the model was trained on.

    Response:
    {
        "classes": ["Braking", "Cruising", "Lane Left", "Lane Right"]
    }
    """
    try:
        return jsonify({'classes': list(model.classes_)}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@prediction_bp.route('/features', methods=['GET'])
def get_features():
    """
    Returns the list of required input features in the correct order.

    Response:
    {
        "features": ["avg_speed", "max_force", ...]
    }
    """
    return jsonify({'features': FEATURE_ORDER}), 200