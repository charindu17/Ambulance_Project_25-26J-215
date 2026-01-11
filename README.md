# AI-Based Emergency Veterinary Triage System
### Machine Learning & Demonstration Component

---

## Overview
This repository contains the **Machine Learning (ML) research component** of the *AI‑Powered Pet Vitals and Symptom Aggregation System*. The system is designed to support **emergency veterinary care** by performing **real‑time triage classification** using a combination of **pet wearable vitals** and **owner‑reported symptoms**.

The ML engine classifies incoming cases into three urgency levels:
- **GREEN** – Non‑Urgent
- **YELLOW** – Urgent
- **RED** – Critical Emergency

The predicted result is packaged as a **Pre‑Vet Alert Package**, allowing veterinarians to prepare appropriate interventions *before* the pet arrives at the clinic.

---

## Problem Statement
Emergency veterinary response often depends on **subjective and incomplete symptom descriptions** provided by distressed pet owners. Most existing pet health monitoring solutions focus on **general wellness tracking** and **retrospective analysis**, rather than **time‑critical emergency triage**.

Furthermore, there is a lack of systems that:
- Integrate **real‑time physiological data** from pet wearables considering owner‑reported symptoms
- Perform **automated emergency prioritization** for companion animals
- Deliver **structured, actionable pre‑arrival alerts** to veterinarians

This research addresses the challenge of **using AI to integrate wearable sensor data and owner‑reported symptoms to perform emergency triage and deliver consolidated pre‑vet alert packages**, thereby improving response efficiency and clinical preparedness.

---

## Novelty of the Proposed System
The proposed ML system introduces several key research innovations:

1. **Emergency‑Focused Veterinary Triage**  
   Unlike conventional pet monitoring systems, this solution is explicitly designed for **emergency prioritization**, not routine health assessment.

2. **Clinically Grounded Dataset Generation**  
   Emergency scenarios are synthetically generated using **veterinary triage standards (AVECCS)** and clinically accepted vital ranges, ensuring medically realistic ground‑truth labels.

3. **Multi‑Modal Decision Framework**  
   The model jointly evaluates **objective wearable vitals** and **subjective owner‑reported symptoms**, enabling context‑aware emergency classification.

4. **Explainable and Trustworthy AI**  
   A **Random Forest classifier** is used to preserve interpretability and alignment with veterinary reasoning, reducing black‑box risk.

5. **Low‑Latency Real‑Time Deployment**  
   The trained model is deployed via a **FastAPI backend**, enabling real‑time inference suitable for emergency environments.

6. **End‑to‑End Alert Lifecycle**  
   From data input → AI triage → database persistence → veterinarian dashboard visualization.

---

## Project Structure
```text
├── dataset_Making.py          # Emergency triage dataset generation
├── validated_triage_data.csv  # Clinically validated dataset
├── model_training.py          # Model training & evaluation
├── vet_triage_model.pkl       # Trained ML model
├── model_columns.pkl          # Feature schema for inference
├── main.py                    # FastAPI backend (real‑time triage)
├── vet_alerts.db              # SQLite database for alerts
├── owner_app.html             # Owner‑facing symptom input UI
├── vet_dashboard.html         # Veterinarian alert dashboard
├── vet_data.csv               # Raw veterinary dataset
├── dataset.csv                # Exploratory dataset
└── README.md
```

---

## System Workflow (ML Perspective)
1. Emergency clinical data is generated and labeled
2. The ML triage model is trained and validated
3. The trained model is deployed as a REST API
4. Owner inputs are submitted via a web interface
5. Triage results are stored and displayed to veterinarians

---

## Step‑by‑Step Execution Guide

### Step 1: Install Required Dependencies
```bash
pip install fastapi uvicorn pandas numpy scikit-learn joblib
```

---

### Step 2: Generate the Emergency Triage Dataset
Run the dataset generator to create clinically realistic emergency cases:
```bash
python dataset_Making.py
```
**Output:**
- `validated_triage_data.csv` containing labeled Green / Yellow / Red cases

---

### Step 3: Train the Machine Learning Model
Train and evaluate the emergency triage classifier:
```bash
python model_training.py
```
**Output:**
- `vet_triage_model.pkl` – trained Random Forest model
- `model_columns.pkl` – feature order used during training
- Console‑printed accuracy and classification report

---

### Step 4: Start the Backend Inference Server
Launch the FastAPI server hosting the trained ML model:
```bash
uvicorn main:app --reload
```
**Available Endpoints:**
- `POST /predict-triage` – Perform emergency triage
- `GET /get-active-alerts` – Retrieve recent alerts

Predictions are automatically stored in `vet_alerts.db`.

---

### Step 5: Run the Owner Application
Open the owner simulation interface in a browser:
```text
owner_app.html
```
**Functionality:**
- Simulates smart‑collar vitals
- Allows symptom selection
- Sends data to the backend for AI‑based triage

---

### Step 6: Open the Veterinarian Dashboard
Open the veterinarian dashboard in a browser:
```text
vet_dashboard.html
```
**Displays:**
- Incoming Pre‑Vet Alert Packages
- Color‑coded urgency levels
- Latest emergency cases in real time

---

## Machine Learning Summary
| Component | Description |
|---------|-------------|
| Model | Random Forest Classifier |
| Inputs | Temperature, Heart Rate, Clinical Symptoms |
| Outputs | Green / Yellow / Red |
| Data Split | 80% Training / 20% Testing |
| Metrics | Accuracy, Precision, Recall, F1‑Score |

---

## Research Contribution
This ML component demonstrates how **AI‑driven emergency triage** can:
- Reduce veterinary response time
- Improve pre‑arrival clinical preparedness
- Minimize subjectivity in emergency assessment
- Enable scalable, low‑latency veterinary emergency care

---

## Future Enhancements
- Breed‑ and species‑specific triage models
- Integration with real smart‑collar hardware
- Federated learning for privacy‑preserving training
- Video‑based symptom analysis using computer vision

---

**This repository represents the Machine Learning research backbone of the AI‑Powered Emergency Veterinary Triage System.**

