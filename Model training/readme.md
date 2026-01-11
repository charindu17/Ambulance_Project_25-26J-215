# Driver Alert and Feedback System

## Overview

This project demonstrates an **end-to-end machine learning pipeline** that detects **vehicle driving behaviors** (such as _Cruising_, _Braking_, and _Lane Changes_) using **smartphone sensor data**.

The system is designed so that:

- Raw sensor data is collected in CSV format
- The data is cleaned and converted into ML-friendly features
- A machine learning model is trained in Python
- The trained model is converted into JavaScript
- Predictions can be run **on-device** (e.g., in a React Native app) without internet or servers

---

## Project Structure

```
├── process_data.py
├── training_data.json
├── ambulance_model.js
```

Each file plays a **specific role** in the pipeline and depends on the previous step.

---

## Step-by-Step: How to Prepare This Project (From Zero)

This section explains **exactly what to do**, even if you have no prior experience.

---

### STEP 1 — Prepare Raw Sensor Data

Start with **CSV files** that contain smartphone sensor readings collected during vehicle movement.

Each CSV file should include:

- Accelerometer data: `acc_x`, `acc_y`, `acc_z`
- GPS speed: `gps_speed`
- Driving label: `label` (button pressed by the passenger)

Example row:

```
acc_x,acc_y,acc_z,gps_speed,label
0.01,0.98,0.05,5.4,Cruising
```

These CSV files are my **input data**. Place them in the same directory as `process_data.py`.

---

### STEP 2 — Run `process_data.py`

This is the **most important file** in the project.

When you run:

```
python process_data.py
```

The script automatically performs **three major tasks**:

#### 2.1 Data Preprocessing

- Reads all CSV files
- Cleans missing or noisy sensor values
- Converts accelerometer data into magnitude
- Calculates jerk (change in acceleration)
- Uses a sliding window technique to group data into 1-second samples

#### 2.2 Feature Engineering

For each window, it extracts numeric features such as:

- Average speed
- Maximum force
- Standard deviation of force
- Minimum force
- Average jerk

Each window is also assigned a label based on the most frequent value.

#### 2.3 Output of Preprocessing

After preprocessing, the script **automatically generates**:

**`training_data.json`**

I do **not** create or edit this file manually.

---

### STEP 3 — Understand `training_data.json`

`training_data.json` is the **clean, machine-learning-ready dataset**.

Each entry represents **one sliding window (≈1 second)** of driving behavior:

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

Important points:

- No raw sensor streams
- No missing (NaN) values
- Only numeric features + label
- Used directly for ML training

---

### STEP 4 — Model Training (Still Inside `process_data.py`)

After creating `training_data.json`, the same script:

- Loads the JSON file
- Splits data into training (80%) and testing (20%)
- Trains a **Random Forest Classifier**
- Handles class imbalance using `class_weight='balanced'`
- Evaluates the model using accuracy, classification report, and confusion matrix

The trained model is saved internally as a `.pkl` file.

---

### STEP 5 — Model Conversion to JavaScript

Finally, `process_data.py` converts the trained Python model into **pure JavaScript logic**.

This produces:

**`ambulance_model.js`**

This file:

- Contains only `if–else` rules
- Does not require Python or ML libraries
- Can be used directly in frontend or mobile apps

---

### STEP 6 — Use `ambulance_model.js` in a Frontend App

In a JavaScript or React Native project:

```js
import score from "./ambulance_model";

const features = [avg_speed, max_force, std_force, min_force, avg_jerk];

const prediction = score(features);
```

The model returns a prediction for the current driving behavior.

---

## How the Files Work Together

```
Raw CSV Sensor Data
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

Each file exists **because of the previous step**.

---

## File Responsibilities Summary

| File                 | Responsibility                              |
| -------------------- | ------------------------------------------- |
| `process_data.py`    | Preprocessing, training, evaluation, export |
| `training_data.json` | Cleaned ML dataset                          |
| `ambulance_model.js` | On-device prediction model                  |

---

## Key Takeaway

> `process_data.py` creates knowledge, `training_data.json` stores knowledge, and `ambulance_model.js` applies knowledge in real time.

---

## Final Notes

- Do not manually edit `training_data.json` or `ambulance_model.js`
- Always rerun `process_data.py` if new CSV data is added
- The pipeline is fully offline and privacy-friendly

---

🎓 This README explains **how the system is prepared, how it works, and how it is used**, step by step.
