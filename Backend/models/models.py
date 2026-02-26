from datetime import datetime
from models import db


class Doctor(db.Model):
    __tablename__ = 'doctors'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    mbbs_reg_number = db.Column(db.String(50), unique=True, nullable=False)
    gender = db.Column(db.String(10), nullable=False)  # 'male' or 'female'
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'mbbs_reg_number': self.mbbs_reg_number,
            'gender': self.gender,
            'created_at': self.created_at.isoformat()
        }


class Patient(db.Model):
    __tablename__ = 'patients'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    age = db.Column(db.Integer, nullable=False)
    gender = db.Column(db.String(10), nullable=False)  # 'male' or 'female'
    weight = db.Column(db.Float, nullable=False)
    height = db.Column(db.Float, nullable=False)
    bmi = db.Column(db.Float, nullable=True)
    fcm_token = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    medical_records = db.relationship('PatientMedicalRecord', backref='patient', lazy=True)
    health_history = db.relationship('PatientHealthHistory', backref='patient', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'age': self.age,
            'gender': self.gender,
            'weight': self.weight,
            'height': self.height,
            'bmi': self.bmi,
            'fcm_token': self.fcm_token,
            'created_at': self.created_at.isoformat()
        }


class PatientMedicalRecord(db.Model):
    __tablename__ = 'patient_medical_records'

    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    file_path = db.Column(db.String(255), nullable=False)
    title = db.Column(db.String(200), nullable=True)
    description = db.Column(db.Text, nullable=True)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'patient_id': self.patient_id,
            'file_path': self.file_path,
            'title': self.title,
            'description': self.description,
            'uploaded_at': self.uploaded_at.isoformat()
        }


class Driver(db.Model):
    __tablename__ = 'drivers'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    vehicle_number = db.Column(db.String(50), unique=True, nullable=False)
    nic = db.Column(db.String(20), unique=True, nullable=True)  # NIC - will be required via validation
    staff_id = db.Column(db.String(50), nullable=True)  # Driver or Staff ID Number (optional)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'vehicle_number': self.vehicle_number,
            'nic': self.nic,
            'staff_id': self.staff_id,
            'created_at': self.created_at.isoformat()
        }


class AmbulanceNavigation(db.Model):
    __tablename__ = 'ambulance_navigations'

    id = db.Column(db.Integer, primary_key=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=False)
    start_latitude = db.Column(db.Float, nullable=False)
    start_longitude = db.Column(db.Float, nullable=False)
    end_latitude = db.Column(db.Float, nullable=False)
    end_longitude = db.Column(db.Float, nullable=False)
    vehicle_number = db.Column(db.String(50), nullable=True)
    status = db.Column(db.String(20), nullable=False, default='PENDING')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    driver = db.relationship('Driver', backref=db.backref('navigations', lazy=True))

    def to_dict(self):
        return {
            'id': self.id,
            'driver_id': self.driver_id,
            'start_location': {
                'lat': self.start_latitude,
                'lng': self.start_longitude
            },
            'end_location': {
                'lat': self.end_latitude,
                'lng': self.end_longitude
            },
            'vehicle_number': self.vehicle_number,
            'status': self.status,
            'created_at': self.created_at.isoformat()
        }


class PatientHealthHistory(db.Model):
    __tablename__ = 'patient_health_historyy'

    id = db.Column(db.Integer, primary_key=True)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)

    # All health metrics are nullable
    age = db.Column(db.Integer, nullable=True)
    bmi = db.Column(db.Float, nullable=True)
    avg_glucose = db.Column(db.Float, nullable=True)
    glucose_trend = db.Column(db.Float, nullable=True)
    max_sbp = db.Column(db.Float, nullable=True)
    sbp_trend = db.Column(db.Float, nullable=True)
    avg_hemoglobin = db.Column(db.Float, nullable=True)
    avg_cholesterol = db.Column(db.Float, nullable=True)

    # Prediction results are nullable
    diabetes_risk = db.Column(db.String(20), nullable=True)
    diabetes_probability = db.Column(db.Float, nullable=True)
    heart_risk = db.Column(db.String(20), nullable=True)
    heart_probability = db.Column(db.Float, nullable=True)
    cholesterol_risk = db.Column(db.String(20), nullable=True)
    cholesterol_probability = db.Column(db.Float, nullable=True)

    recorded_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'patient_id': self.patient_id,
            'age': self.age,
            'bmi': self.bmi,
            'avg_glucose': self.avg_glucose,
            'glucose_trend': self.glucose_trend,
            'max_sbp': self.max_sbp,
            'sbp_trend': self.sbp_trend,
            'avg_hemoglobin': self.avg_hemoglobin,
            'avg_cholesterol': self.avg_cholesterol,
            'predictions': {
                'diabetes_risk': self.diabetes_risk,
                'diabetes_probability': self.diabetes_probability,
                'heart_risk': self.heart_risk,
                'heart_probability': self.heart_probability,
                'cholesterol_risk': self.cholesterol_risk,
                'cholesterol_probability': self.cholesterol_probability
            },
            'recorded_at': self.recorded_at.isoformat() if self.recorded_at else None
        }


class NotificationAcknowledgment(db.Model):
    __tablename__ = 'notification_acknowledgments'

    id = db.Column(db.Integer, primary_key=True)
    navigation_id = db.Column(db.Integer, db.ForeignKey('ambulance_navigations.id'), nullable=False)
    patient_id = db.Column(db.Integer, db.ForeignKey('patients.id'), nullable=False)
    acknowledgment_type = db.Column(db.String(20), nullable=False, default='AWARE')  # SEEN, AWARE, MOVING_ASIDE
    acknowledged_at = db.Column(db.DateTime, default=datetime.utcnow)

    navigation = db.relationship('AmbulanceNavigation', backref=db.backref('acknowledgments', lazy=True))
    patient = db.relationship('Patient', backref=db.backref('notification_acknowledgments', lazy=True))

    def to_dict(self):
        return {
            'id': self.id,
            'navigation_id': self.navigation_id,
            'patient_id': self.patient_id,
            'acknowledgment_type': self.acknowledgment_type,
            'acknowledged_at': self.acknowledged_at.isoformat() if self.acknowledged_at else None
        }
