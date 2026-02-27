from flask import Blueprint, request, jsonify
from models import db
from models.models import AmbulanceNavigation, Driver

navigation_bp = Blueprint('navigation', __name__, url_prefix='/ambulance-navigation')


@navigation_bp.route('', methods=['POST'])
def create_navigation():
    try:
        data = request.get_json()

        driver = Driver.query.get(data['driver_id'])
        if not driver:
            return jsonify({'error': 'Driver not found'}), 404

        navigation = AmbulanceNavigation(
            driver_id=data['driver_id'],
            start_latitude=data['start_latitude'],
            start_longitude=data['start_longitude'],
            end_latitude=data['end_latitude'],
            end_longitude=data['end_longitude'],
            vehicle_number=data.get('vehicle_number')
        )

        db.session.add(navigation)
        db.session.commit()

        return jsonify({'message': 'Navigation created successfully', 'navigation': navigation.to_dict()}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@navigation_bp.route('/<int:id>', methods=['GET'])
def get_navigation(id):
    try:
        navigation = AmbulanceNavigation.query.get(id)
        if not navigation:
            return jsonify({'error': 'Navigation not found'}), 404
        return jsonify({'navigation': navigation.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@navigation_bp.route('/driver/<int:driver_id>', methods=['GET'])
def get_driver_navigations(driver_id):
    try:
        driver = Driver.query.get(driver_id)
        if not driver:
            return jsonify({'error': 'Driver not found'}), 404

        navigations = AmbulanceNavigation.query.filter_by(driver_id=driver_id).all()
        return jsonify({'navigations': [nav.to_dict() for nav in navigations]}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@navigation_bp.route('/<int:id>', methods=['PUT'])
def update_navigation(id):
    try:
        navigation = AmbulanceNavigation.query.get(id)
        if not navigation:
            return jsonify({'error': 'Navigation not found'}), 404

        data = request.get_json()

        if 'end_latitude' in data:
            navigation.end_latitude = data['end_latitude']

        if 'end_longitude' in data:
            navigation.end_longitude = data['end_longitude']

        if 'vehicle_number' in data:
            navigation.vehicle_number = data['vehicle_number']

        db.session.commit()
        return jsonify({'message': 'Navigation updated successfully', 'navigation': navigation.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@navigation_bp.route('/<int:id>', methods=['DELETE'])
def delete_navigation(id):
    try:
        navigation = AmbulanceNavigation.query.get(id)
        if not navigation:
            return jsonify({'error': 'Navigation not found'}), 404

        db.session.delete(navigation)
        db.session.commit()
        return jsonify({'message': 'Navigation deleted successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@navigation_bp.route('/<int:id>/status', methods=['PATCH'])
def update_navigation_status(id):
    try:
        navigation = AmbulanceNavigation.query.get(id)
        if not navigation:
            return jsonify({'error': 'Navigation not found'}), 404

        data = request.get_json()

        valid_statuses = ['PENDING', 'STARTED', 'COMPLETED']
        if 'status' not in data or data['status'] not in valid_statuses:
            return jsonify({'error': f'Invalid status. Must be one of: {", ".join(valid_statuses)}'}), 400

        navigation.status = data['status']
        db.session.commit()

        return jsonify({'message': 'Status updated successfully', 'navigation': navigation.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
