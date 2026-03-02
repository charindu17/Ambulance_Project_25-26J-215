from flask import Blueprint, request, jsonify
from models import db
from models.models import Patient, NotificationAcknowledgment, AmbulanceNavigation
from services.notification_service import NotificationService

notification_bp = Blueprint('notification', __name__, url_prefix='/notifications')


@notification_bp.route('/send', methods=['POST'])
def send_notification_to_users():
    """
    Send notification to specific patients by their IDs.

    Request body:
    {
        "patient_ids": [1, 2, 3],
        "title": "Notification Title",
        "body": "Notification body message",
        "data": {"key": "value"}  // optional
    }
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        patient_ids = data.get('patient_ids')
        title = data.get('title')
        body = data.get('body')
        extra_data = data.get('data', {})

        if not patient_ids or not isinstance(patient_ids, list):
            return jsonify({'error': 'patient_ids is required and must be a list'}), 400
        if not title:
            return jsonify({'error': 'title is required'}), 400
        if not body:
            return jsonify({'error': 'body is required'}), 400

        # Get patients with FCM tokens
        patients = Patient.query.filter(
            Patient.id.in_(patient_ids),
            Patient.fcm_token.isnot(None)
        ).all()

        if not patients:
            return jsonify({
                'error': 'No patients found with FCM tokens',
                'requested_ids': patient_ids
            }), 404

        tokens = [p.fcm_token for p in patients]

        notification_service = NotificationService()
        result = notification_service.send_to_multiple_tokens(
            tokens=tokens,
            title=title,
            body=body,
            data=extra_data
        )

        if not result['success']:
            return jsonify({'error': result['error']}), 500

        return jsonify({
            'message': 'Notifications sent',
            'total_requested': len(patient_ids),
            'tokens_found': len(tokens),
            'success_count': result['success_count'],
            'failure_count': result['failure_count'],
            'responses': result['responses']
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@notification_bp.route('/send-all', methods=['POST'])
def send_notification_to_all():
    """
    Send notification to all patients with FCM tokens.

    Request body:
    {
        "title": "Notification Title",
        "body": "Notification body message",
        "data": {"key": "value"}  // optional
    }
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        title = data.get('title')
        body = data.get('body')
        extra_data = data.get('data', {})

        if not title:
            return jsonify({'error': 'title is required'}), 400
        if not body:
            return jsonify({'error': 'body is required'}), 400

        # Get all patients with FCM tokens
        patients = Patient.query.filter(Patient.fcm_token.isnot(None)).all()

        if not patients:
            return jsonify({'error': 'No patients found with FCM tokens'}), 404

        tokens = [p.fcm_token for p in patients]

        notification_service = NotificationService()
        result = notification_service.send_to_multiple_tokens(
            tokens=tokens,
            title=title,
            body=body,
            data=extra_data
        )

        if not result['success']:
            return jsonify({'error': result['error']}), 500

        return jsonify({
            'message': 'Notifications sent to all patients',
            'total_patients_with_tokens': len(tokens),
            'success_count': result['success_count'],
            'failure_count': result['failure_count'],
            'responses': result['responses']
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@notification_bp.route('/acknowledge', methods=['POST'])
def acknowledge_notification():
    """
    Acknowledge an ambulance notification (I'm Aware / Ambulance Seen button).

    Request body:
    {
        "navigation_id": 1,
        "patient_id": 123,
        "acknowledgment_type": "AWARE"  // SEEN, AWARE, MOVING_ASIDE
    }
    """
    try:
        data = request.get_json()

        if not data:
            return jsonify({'error': 'Request body is required'}), 400

        navigation_id = data.get('navigation_id')
        patient_id = data.get('patient_id')
        acknowledgment_type = data.get('acknowledgment_type', 'AWARE')

        if not navigation_id:
            return jsonify({'error': 'navigation_id is required'}), 400
        if not patient_id:
            return jsonify({'error': 'patient_id is required'}), 400

        # Validate acknowledgment type
        valid_types = ['SEEN', 'AWARE', 'MOVING_ASIDE']
        if acknowledgment_type not in valid_types:
            return jsonify({'error': f'acknowledgment_type must be one of: {valid_types}'}), 400

        # Verify navigation exists
        navigation = AmbulanceNavigation.query.get(navigation_id)
        if not navigation:
            return jsonify({'error': 'Navigation not found'}), 404

        # Verify patient exists
        patient = Patient.query.get(patient_id)
        if not patient:
            return jsonify({'error': 'Patient not found'}), 404

        # Check if already acknowledged
        existing = NotificationAcknowledgment.query.filter_by(
            navigation_id=navigation_id,
            patient_id=patient_id
        ).first()

        if existing:
            # Update existing acknowledgment
            existing.acknowledgment_type = acknowledgment_type
            db.session.commit()
            return jsonify({
                'success': True,
                'message': 'Acknowledgment updated',
                'acknowledgment': existing.to_dict()
            }), 200

        # Create new acknowledgment
        acknowledgment = NotificationAcknowledgment(
            navigation_id=navigation_id,
            patient_id=patient_id,
            acknowledgment_type=acknowledgment_type
        )

        db.session.add(acknowledgment)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Notification acknowledged',
            'acknowledgment': acknowledgment.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@notification_bp.route('/navigation/<int:navigation_id>/acknowledgments', methods=['GET'])
def get_navigation_acknowledgments(navigation_id):
    """Get all acknowledgments for a specific navigation/ambulance trip."""
    try:
        navigation = AmbulanceNavigation.query.get(navigation_id)
        if not navigation:
            return jsonify({'error': 'Navigation not found'}), 404

        acknowledgments = NotificationAcknowledgment.query.filter_by(
            navigation_id=navigation_id
        ).order_by(NotificationAcknowledgment.acknowledged_at.desc()).all()

        return jsonify({
            'navigation_id': navigation_id,
            'acknowledgments': [ack.to_dict() for ack in acknowledgments],
            'total': len(acknowledgments)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


