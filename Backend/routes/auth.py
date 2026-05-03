from flask import Blueprint, request, jsonify
from models import db
from models.models import Doctor, Patient, Driver
from utils.helpers import hash_password, verify_password

auth_bp = Blueprint('auth', __name__, url_prefix='/auth')


# ============ Doctor Auth ============
@auth_bp.route('/doctor/register', methods=['POST'])
def register_doctor():
    try:
        data = request.get_json()

        if Doctor.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email already exists'}), 400

        if Doctor.query.filter_by(mbbs_reg_number=data['mbbs_reg_number']).first():
            return jsonify({'error': 'MBBS registration number already exists'}), 400

        doctor = Doctor(
            name=data['name'],
            email=data['email'],
            password=hash_password(data['password']),
            mbbs_reg_number=data['mbbs_reg_number'],
            gender=data['gender']
        )

        db.session.add(doctor)
        db.session.commit()

        return jsonify({'message': 'Doctor registered successfully', 'doctor': doctor.to_dict()}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/doctor/login', methods=['POST'])
def login_doctor():
    try:
        data = request.get_json()
        doctor = Doctor.query.filter_by(email=data['email']).first()

        if not doctor or not verify_password(data['password'], doctor.password):
            return jsonify({'error': 'Invalid email or password'}), 401

        return jsonify({'message': 'Login successful', 'doctor': doctor.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============ Patient Auth ============
@auth_bp.route('/patient/register', methods=['POST'])
def register_patient():
    try:
        data = request.get_json()

        if Patient.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email already exists'}), 400

        # Calculate BMI
        height_m = data['height'] / 100  # assuming height in cm
        bmi = data['weight'] / (height_m ** 2)

        patient = Patient(
            name=data['name'],
            email=data['email'],
            password=hash_password(data['password']),
            age=data['age'],
            gender=data['gender'],
            weight=data['weight'],
            height=data['height'],
            bmi=round(bmi, 2)
        )

        db.session.add(patient)
        db.session.commit()

        return jsonify({'message': 'Patient registered successfully', 'patient': patient.to_dict()}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/patient/login', methods=['POST'])
def login_patient():
    try:
        data = request.get_json()
        patient = Patient.query.filter_by(email=data['email']).first()

        if not patient or not verify_password(data['password'], patient.password):
            return jsonify({'error': 'Invalid email or password'}), 401

        return jsonify({'message': 'Login successful', 'patient': patient.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ============ Driver Auth ============
@auth_bp.route('/driver/register', methods=['POST'])
def register_driver():
    try:
        data = request.get_json()

        # NIC is required
        if 'nic' not in data or not data['nic']:
            return jsonify({'error': 'NIC is required'}), 400

        if Driver.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email already exists'}), 400

        if Driver.query.filter_by(vehicle_number=data['vehicle_number']).first():
            return jsonify({'error': 'Vehicle number already exists'}), 400

        if Driver.query.filter_by(nic=data['nic']).first():
            return jsonify({'error': 'NIC already exists'}), 400

        driver = Driver(
            name=data['name'],
            email=data['email'],
            password=hash_password(data['password']),
            vehicle_number=data['vehicle_number'],
            nic=data['nic'],
            staff_id=data.get('staff_id')  # Optional
        )

        db.session.add(driver)
        db.session.commit()

        return jsonify({'message': 'Driver registered successfully', 'driver': driver.to_dict()}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/driver/login', methods=['POST'])
def login_driver():
    try:
        data = request.get_json()
        driver = Driver.query.filter_by(email=data['email']).first()

        if not driver or not verify_password(data['password'], driver.password):
            return jsonify({'error': 'Invalid email or password'}), 401

        return jsonify({'message': 'Login successful', 'driver': driver.to_dict()}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500