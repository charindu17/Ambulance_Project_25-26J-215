from flask import Blueprint, request, jsonify
from models import db
from models.models import Driver
from utils.helpers import hash_password

driver_bp = Blueprint('driver', __name__, url_prefix='/drivers')


@driver_bp.route('', methods=['GET'])
def get_all_drivers():
    try:
        drivers = Driver.query.all()
        return jsonify({'drivers': [driver.to_dict() for driver in drivers]}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@driver_bp.route('/<int:id>', methods=['GET'])
def get_driver(id):
    try:
        driver = Driver.query.get(id)
        if not driver:
            return jsonify({'error': 'Driver not found'}), 404
        return jsonify({'driver': driver.to_dict()}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@driver_bp.route('/<int:id>', methods=['PUT'])
def update_driver(id):
    try:
        driver = Driver.query.get(id)
        if not driver:
            return jsonify({'error': 'Driver not found'}), 404

        data = request.get_json()

        if 'name' in data:
            driver.name = data['name']

        if 'vehicle_number' in data:
            existing = Driver.query.filter_by(vehicle_number=data['vehicle_number']).first()
            if existing and existing.id != id:
                return jsonify({'error': 'Vehicle number already exists'}), 400
            driver.vehicle_number = data['vehicle_number']

        if 'nic' in data:
            existing = Driver.query.filter_by(nic=data['nic']).first()
            if existing and existing.id != id:
                return jsonify({'error': 'NIC already exists'}), 400
            driver.nic = data['nic']

        if 'staff_id' in data:
            driver.staff_id = data['staff_id']

        if 'password' in data:
            driver.password = hash_password(data['password'])

        db.session.commit()
        return jsonify({'message': 'Driver updated successfully', 'driver': driver.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@driver_bp.route('/<int:id>', methods=['DELETE'])
def delete_driver(id):
    try:
        driver = Driver.query.get(id)
        if not driver:
            return jsonify({'error': 'Driver not found'}), 404

        db.session.delete(driver)
        db.session.commit()
        return jsonify({'message': 'Driver deleted successfully'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
