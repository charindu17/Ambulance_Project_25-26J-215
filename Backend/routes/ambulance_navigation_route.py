from models.models import AmbulanceNavigation, Patient
from services.notification_service import NotificationService
from datetime import datetime


def send_active_navigation_notifications(app):
    """
    Scheduled job that sends notifications every 5 minutes for active ambulance navigations.

    This function is called by APScheduler every 5 minutes and:
    1. Queries all navigations with status = 'STARTED'
    2. Gets all patients with FCM tokens
    3. Sends notifications to all patients about active ambulances
    """
    with app.app_context():
        try:
            # Find all active navigations
            active_navigations = AmbulanceNavigation.query.filter_by(status='STARTED').all()

            if not active_navigations:
                return

            # Get all patients with FCM tokens
            patients = Patient.query.filter(Patient.fcm_token.isnot(None)).all()

            if not patients:
                return

            tokens = [p.fcm_token for p in patients]

            # Send notification for each active navigation
            notification_service = NotificationService()

            for navigation in active_navigations:
                vehicle_number = navigation.vehicle_number or "Unknown"

                title = "Ambulance Alert"
                body = f"Ambulance {vehicle_number} is on the way. Navigation ID: {navigation.id}"

                data = {
                    'navigation_id': str(navigation.id),
                    'vehicle_number': vehicle_number,
                    'status': navigation.status,
                    'timestamp': datetime.utcnow().isoformat()
                }

                result = notification_service.send_to_multiple_tokens(
                    tokens=tokens,
                    title=title,
                    body=body,
                    data=data
                )

                if result['success']:
                    print(f"[{datetime.utcnow()}] Ambulance notification sent for navigation {navigation.id}: "
                          f"success={result['success_count']}, failed={result['failure_count']}")
                else:
                    print(f"[{datetime.utcnow()}] Failed to send ambulance notification for navigation {navigation.id}: {result['error']}")

        except Exception as e:
            print(f"[{datetime.utcnow()}] Error in send_active_navigation_notifications: {str(e)}")
