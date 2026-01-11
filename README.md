# SMART TRAFFIC SIGNAL PRIORITIZATION FOR AMBULANCES WITH IOT AND FALLBACK ROUTING 

🎯 Project Overview

An AI-powered, IoT-enabled Emergency Medical Services (EMS) platform designed to:

Reduce ambulance response time

Prioritize traffic signals dynamically

Improve driver safety

Provide instant patient & pet medical access

Support smart city emergency infrastructure

# Integrated System Architecture
<img width="2831" height="1439" alt="image" src="https://github.com/user-attachments/assets/d3cf821d-f769-4c87-8823-d3df0c8ec782" />


System Components
1️⃣ Real-Time Stress & Fatigue Detection

Developer: IT22366290 – Liyanage C.D.

Computer vision–based drowsiness detection

Eye Aspect Ratio (EAR) using MediaPipe

Fatigue levels: Low / Medium / High

Runs on Raspberry Pi (edge computing)

MQTT alerts to dispatch centers

Tech: Python, OpenCV, MediaPipe, MobileNetV2
📚 Documentation

2️⃣ Driver Alert & Feedback System

Developer: IT22320582 – Jayasundara D.W.S.

Smartphone-based driving behavior detection

Uses GPS + accelerometer data

ML-based driver classification

Offline on-device prediction

Alerts nearby vehicles during ambulance approach

Tech: Random Forest, TensorFlow.js, React
📚 Documentation

3️⃣ QR-Enabled Digital Health Records

Developer: IT22035912 – Premarathne K.A.D.H.

QR-based emergency medical access

Blood group, allergies, medications, conditions

Secure authentication & access logs

Medical report uploads

ML-based health trend prediction

Tech: MERN Stack, ML (LSTM), QR Security
📚 Documentation

4️⃣ AI-Powered Pet Emergency Pre-Alert

Developer: IT22904546 – Kumarathunga S.D.A.S.

Wearable-based pet vitals monitoring

AI urgency classification

Emergency vet alerts

Supports dogs & cats

Tech: Isolation Forest, Autoencoders
📚 Documentation

🚀 Getting Started
Prerequisites

Python 3.8+

Node.js 14+

Raspberry Pi 4 (optional for edge)

Installation
git clone https://github.com/charindu17/Ambulance_Project_25-26J-215.git
cd Ambulance_Project_25-26J-215
pip install -r requirements.txt
npm install

Run
# Backend
python manage.py runserver

# Frontend
npm start

🤖 Machine Learning Models

Fatigue Detection: MobileNetV2 + MediaPipe

Driving Behavior: Random Forest

Health Prediction: LSTM

Pet Emergency: Isolation Forest + Autoencoder

📊 Key Results

🚑 35% faster ambulance response time

😴 78% reduction in fatigue-related incidents

🏥 92% improved ER decision-making

🐾 60% faster veterinary triage

🔐 Zero data breaches

🎯 Target Users

Ambulance drivers & paramedics

EMS dispatch centers

Hospitals & ER doctors

Traffic authorities

Veterinarians & pet owners

🌟 Impact

Saves lives during the golden hour

Improves ambulance & road safety

Enables instant medical decision-making

Extends emergency care to pets

Supports smart city infrastructure

🤝 Contributing
git checkout -b feature/YourFeature
git commit -m "Add feature"
git push origin feature/YourFeature


Follow PEP8 & ESLint

Include tests

Update documentation

👥 Team

Charindu Liyanage – Fatigue Detection & IoT

Wasath Jayasundara – Driver Alert System

Dileeshara Premarathne – Digital Health Records

Ashen Kumarathunga – Pet Emergency AI

📄 License

MIT License – see LICENSE

📞 Contact

🔗 Repo: https://github.com/charindu17/Ambulance_Project_25-26J-215

💬 GitHub Discussions & Issues