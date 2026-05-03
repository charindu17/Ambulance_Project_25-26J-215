from models.models import AmbulanceNavigation, Patient
from services.notification_service import NotificationService
from datetime import datetime
import requests  # NEW: to call our own prediction endpoint

# ── NEW: prediction endpoint (same backend, loopback call) ─────────────────
# Since the ML model is served via /prediction/predict on this same backend,
# the scheduler calls it internally to decide alarm vs. normal notification
# for each patient vehicle. This mirrors what the Flutter SensorService does
# on the device side, making the logic consistent end-to-end.
PREDICTION_ENDPOINT = "http://localhost:5001/prediction/predict"

# Feature order must match FEATURE_ORDER in ambulance_navigation_route.py
FEATURE_ORDER = [
    "avg_speed",
    "max_force",
    "std_force",
    "min_force",
    "avg_jerk",
    "avg_lateral",
    "max_lateral",
]


def _get_latest_sensor_features(patient_id: int) -> dict | None:
    """
    Retrieve the most recent sensor feature window for a patient vehicle.

    In a production deployment these features would be written to the database
    by the patient's app (via a dedicated /sensor-data endpoint) every few
    seconds. For this showcase the function queries the patient record for
    any stored sensor snapshot. If none is present it returns None and the
    caller falls back to sending the normal notification.

    Returns a dict with the 7 feature keys or None.
    """
    try:
        from models.models import PatientSensorSnapshot  # imported lazily to avoid circular imports
        snapshot = (
            PatientSensorSnapshot.query
            .filter_by(patient_id=patient_id)
            .order_by(PatientSensorSnapshot.recorded_at.desc())
            .first()
        )
        if snapshot is None:
            return None
        return {
            "avg_speed":   snapshot.avg_speed,
            "max_force":   snapshot.max_force,
            "std_force":   snapshot.std_force,
            "min_force":   snapshot.min_force,
            "avg_jerk":    snapshot.avg_jerk,
            "avg_lateral": snapshot.avg_lateral,
            "max_lateral": snapshot.max_lateral,
        }
    except Exception as e:
        print(f"[Scheduler] Could not fetch sensor snapshot for patient {patient_id}: {e}")
        return None


def _predict_driving_behaviour(features: dict) -> str | None:
    """
    Call the backend Random Forest prediction endpoint with the supplied
    feature window and return the predicted label (e.g. 'Cruising').

    Returns None on any error so the caller can fall back gracefully.
    """
    try:
        resp = requests.post(
            PREDICTION_ENDPOINT,
            json=features,
            timeout=5,
        )
        if resp.status_code == 200:
            label = resp.json().get("prediction")
            confidence = resp.json().get("confidence", 0.0)
            print(f"[Scheduler] ML prediction → {label} ({confidence:.2%})")
            return label if confidence > 0.60 else None
        else:
            print(f"[Scheduler] Prediction endpoint returned {resp.status_code}")
            return None
    except Exception as e:
        print(f"[Scheduler] Prediction call failed: {e}")
        return None


def _is_not_yielding(prediction_label: str | None) -> bool:
    """
    Returns True when the model predicts the vehicle is still cruising,
    meaning it has not yet slowed down or moved aside for the ambulance.
    These vehicles should receive the ALARM notification.
    """
    return prediction_label == "Cruising"


def send_active_navigation_notifications(app):
    """
    Scheduled job that runs every 5 minutes for active ambulance navigations.

    For each patient vehicle the scheduler now:
      1. Fetches the latest sensor feature window stored by that patient's app.
      2. Calls POST /prediction/predict to get the ML model's behaviour label.
      3. Sends an ALARM notification if the vehicle is still cruising (not
         yielded), or a normal notification if it has already moved aside.
      4. Falls back to the normal notification when no sensor data is available.

    This is unchanged from before for navigations with no sensor data so that
    existing behaviour is fully preserved.
    """
    with app.app_context():
        try:
            # Find all active navigations
            active_navigations = AmbulanceNavigation.query.filter_by(
                status='STARTED'
            ).all()

            if not active_navigations:
                return

            # Get all patients with FCM tokens
            patients = Patient.query.filter(
                Patient.fcm_token.isnot(None)
            ).all()

            if not patients:
                return

            notification_service = NotificationService()

            for navigation in active_navigations:
                vehicle_number = navigation.vehicle_number or "Unknown"

                for patient in patients:
                    # ── NEW: per-patient prediction logic ─────────────────
                    features = _get_latest_sensor_features(patient.id)
                    prediction = _predict_driving_behaviour(features) \
                        if features else None
                    alarm = _is_not_yielding(prediction)
                    # ──────────────────────────────────────────────────────

                    if alarm:
                        # Vehicle has NOT yielded → send ALARM notification
                        # ── CONTENT (scheduler alarm notification): update header & body here ──
                        title = "🚨 Ambulance On The Way!"
                        body = (
                            f"URGENT: Ambulance {vehicle_number} is approaching. "
                            "Please move aside immediately!"
                        )
                        data = {
                            'navigation_id': str(navigation.id),
                            'vehicle_number': vehicle_number,
                            'status': navigation.status,
                            'alert_type': 'ALARM',
                            'ml_prediction': prediction or 'Unknown',
                            'timestamp': datetime.utcnow().isoformat(),
                        }
                    else:
                        # Vehicle already yielded / no data → normal notification
                        # ── CONTENT (scheduler normal notification): update header & body here ──
                        title = "Ambulance On The Way!"
                        body = (
                            f"Ambulance {vehicle_number} is now active and "
                            "heading to the destination"
                        )
                        data = {
                            'navigation_id': str(navigation.id),
                            'vehicle_number': vehicle_number,
                            'status': navigation.status,
                            'alert_type': 'NORMAL',
                            'timestamp': datetime.utcnow().isoformat(),
                        }

                    result = notification_service.send_to_token(
                        token=patient.fcm_token,
                        title=title,
                        body=body,
                        data=data,
                    )

                    kind = "ALARM" if alarm else "NORMAL"
                    if result['success']:
                        print(
                            f"[{datetime.utcnow()}] [{kind}] notification sent "
                            f"to patient {patient.id} for navigation {navigation.id}"
                        )
                    else:
                        print(
                            f"[{datetime.utcnow()}] Failed to send [{kind}] to "
                            f"patient {patient.id}: {result.get('error')}"
                        )

        except Exception as e:
            print(
                f"[{datetime.utcnow()}] Error in send_active_navigation_notifications: {e}"
            )