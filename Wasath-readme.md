# Driver Alert & Feedback System

**Developer**: IT22320582 – Jayasundara D.W\.S

## Overview

This project presents a **complete end-to-end journey** from **mobile-based data collection** to **machine learning–powered driving behavior prediction on mobile/frontend**.

The system consists of **two tightly connected parts**:

1. **Data Collector Mobile App** – built using **Expo (React Native)** to collect real-world driving sensor data
2. **Machine Learning Pipeline & Model** – built in **Python**, then exported to **JavaScript** for on-device prediction

Together, these components enable a fully offline, privacy-friendly system that detects driving behaviors such as:

- Cruising
- Braking
- Lane changes

---

## Problem Statement

In congested urban areas such as Sri Lanka, ambulances often face serious delays due to traffic congestion and ineffective driver alert mechanisms. Traditional alerts like sirens and flashing lights are frequently ignored, with only about 60–70% driver compliance. Existing digital and IoT-based solutions suffer from high latency, lack personalization, and operate mainly as one-way systems without real-time feedback. Additionally, the absence of locally collected driving-behavior datasets limits the development of accurate, context-aware models. Therefore, there is a need for an intelligent, adaptive system that can better understand driving behavior and support more effective ambulance movement in urban traffic.

---

## Novelty of the Proposed System

The novelty of this system lies in its **mobile-centric, end-to-end approach** that connects real-world data collection with on-device machine learning prediction. Unlike traditional infrastructure-heavy solutions, this project uses a custom mobile app to collect local driving data, applies machine learning to understand individual driver behavior/vehicle movements, send personalized alerts based on that individual driver behavior/vehicle movements deploys the trained model directly on mobile/frontend platforms as JavaScript. The system is fully offline, privacy-friendly, low-cost, and designed to serve as a foundation for future adaptive driver alerts and feedback mechanisms, making it suitable for real-world deployment in developing urban environments.

---

## System Journey (High-Level)

```
Mobile App (Sensor Data Collection)
        ↓
Raw CSV Sensor Data
        ↓
Data Preprocessing & Feature Engineering
        ↓
Machine Learning Model Training (Python)
        ↓
Model Conversion to JavaScript
        ↓
Mobile / Frontend Real-Time Prediction
```

This README explains **each step of this journey in order**, from start to finish.

---

## PART 1 - Data Collector Mobile App

### Purpose

The Data Collector App is responsible for **capturing real driving data** using smartphone sensors.

It records:

- Accelerometer data (`acc_x`, `acc_y`, `acc_z`)
- GPS speed
- User-selected driving labels (via buttons)

This app ensures that **ground-truth labeled data** is collected in real-world conditions.

---

### Technology Used

- **Expo (React Native)**
- JavaScript / TypeScript
- Smartphone sensors (GPS, Accelerometer)

---

### How to Run the Data Collector App

1. Install dependencies:

```bash
npm install
```

2. Start the app:

```bash
npx expo start
```

3. Open the app using:

- Expo Go (Android)
- Android Emulator
- Physical device

---

### What the App Produces

The app exports **CSV files** containing rows like:

```
acc_x,acc_y,acc_z,gps_speed,label
0.01,0.98,0.05,5.4,Cruising
```

These CSV files are the **starting point** for the machine learning pipeline.

---

## PART 2 - Machine Learning Pipeline

### Project Structure

```
├── process_data.py
├── training_data.json
├── ambulance_model.js
```

Each file represents a **distinct stage** in the ML pipeline.

---

## STEP 1 - Raw CSV Sensor Data

- Collected from the mobile app
- Contains noisy, raw sensor streams
- Not suitable for direct ML training

These CSV files are placed in the same directory as `process_data.py`.

---

## STEP 2 - Data Preprocessing (`process_data.py`)

This is the **core pipeline script**.

When executed:

```bash
python process_data.py
```

It performs:

### 2.1 Data Cleaning

- Handles missing GPS values
- Reduces sensor noise
- Converts 3-axis acceleration into magnitude
- Calculates jerk (change in acceleration)

### 2.2 Sliding Window Processing

- Groups data into \~1 second windows
- Ensures fixed-size ML samples
- Removes incomplete windows

### 2.3 Feature Engineering

For each window, it extracts:

- Average speed
- Maximum force
- Minimum force
- Force standard deviation
- Average jerk

Each window is assigned a label using **majority voting**.

---

## STEP 3 - `training_data.json`

After preprocessing, the script automatically generates:

\`\`

Example entry:

```json
{
  "label": "Braking",
  "avg_speed": 4.65,
  "max_force": 1.18,
  "std_force": 0.07,
  "min_force": 0.83,
  "avg_jerk": 0.05
}
```

### Key Properties

- ML-ready
- No NaN values
- No raw sensor streams
- Never edited manually

This file acts as the **bridge between data collection and model training**.

---

## STEP 4 - Model Training (Python)

Still inside `process_data.py`, the pipeline:

- Loads `training_data.json`
- Splits data into training (80%) and testing (20%)
- Trains a **Random Forest Classifier**
- Handles class imbalance using `class_weight='balanced'`
- Evaluates performance using:
  - Accuracy
  - Classification report
  - Confusion matrix

The trained model is saved internally as a `.pkl` file.

---

## STEP 5 - Model Conversion to JavaScript

The trained Python model is converted into **pure JavaScript logic**.

This produces:

\`\`

### Why JavaScript?

- Works inside React Native
- No backend required
- Fully offline inference
- Preserves user privacy

The file contains a large `if–else` decision function generated from the trained Random Forest.

---

## STEP 6 - Frontend / Mobile Prediction

In a mobile or frontend app:

```js
import score from "./ambulance_model";

const features = [
  avg_speed,
  max_force,
  std_force,
  min_force,
  avg_jerk
];

const prediction = score(features);
```

The model instantly returns the predicted driving behavior.

---

## End-to-End File Interaction

```
Data Collector App
        ↓
Raw CSV Files
        ↓
process_data.py
        ↓
training_data.json
        ↓
Model Training
        ↓
ambulance_model.js
        ↓
Mobile / Frontend Prediction
```

---

## Responsibilities Summary

| Component            | Responsibility                                  |
| -------------------- | ----------------------------------------------- |
| Data Collector App   | Collect labeled sensor data                     |
| `process_data.py`    | Cleaning, feature engineering, training, export |
| `training_data.json` | Clean ML dataset                                |
| `ambulance_model.js` | On-device prediction logic                      |

---

## Key Takeaway

> This system demonstrates a complete real-world pipeline where data is collected on a mobile device, transformed into knowledge using machine learning, and deployed back onto mobile/frontend platforms for real-time, offline decision-making.

---

## Final Notes

- CSV data comes **only** from the mobile app
- `training_data.json` and `ambulance_model.js` are **auto-generated**
- Any new data requires rerunning `process_data.py`
- The system is modular, explainable, and privacy-friendly

## **References**

- Y. Chen et al., "Emergency vehicle priority at intersections using RFID and centralized control," IEEE Trans. Veh. Technol., vol. 69, no. 12, pp. 14567-14578, Dec. 2020.
- V. K. Saini et al., "GSM and GPS based vehicle location and tracking system," in Proc. Int. Conf. Recent Adv. Eng. Technol., New Delhi, India, 2019, pp. 1-5.
- Y. Wang et al., "Predicting driver yielding behavior to emergency vehicles using machine learning," Transp. Res. Part C: Emerg. Technol., vol. 128, p. 103198, 2021.

---

This README documents the **full journey from data collection to mobile prediction**, end to end.

