from flask import Flask, jsonify
from flask_cors import CORS
from config import Config
from models import db
from routes.auth import auth_bp
from routes.doctor import doctor_bp
from routes.patient import patient_bp
from routes.prediction import prediction_bp
from routes.driver import driver_bp
from routes.ambulance_navigation import navigation_bp
from routes.notification import notification_bp
from apscheduler.schedulers.background import BackgroundScheduler
from services.ambulance_notification_scheduler import send_active_navigation_notifications
import atexit


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize extensions
    CORS(app)
    db.init_app(app)

    # Register blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(doctor_bp)
    app.register_blueprint(patient_bp)
    app.register_blueprint(prediction_bp)
    app.register_blueprint(driver_bp)
    app.register_blueprint(navigation_bp)
    app.register_blueprint(notification_bp)

    # Create tables
    with app.app_context():
        db.create_all()

    # Initialize scheduler for recurring ambulance notifications
    scheduler = BackgroundScheduler()
    scheduler.add_job(
        func=send_active_navigation_notifications,
        args=[app],
        trigger="interval",
        minutes=2,
        distance=0.8,
        id='ambulance_notification_job',
        name='Send ambulance notifications within 0.8 kilometers every 2 minutes',
        replace_existing=True
    )
    scheduler.start()

    # Shutdown scheduler gracefully
    atexit.register(lambda: scheduler.shutdown())

    @app.route('/health', methods=['GET'])
    def health():
        return jsonify({'status': 'ok'}), 200

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5001, debug=True)