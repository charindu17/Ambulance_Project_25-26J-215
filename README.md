# Ambulance_Project_25-26J-215  
## Research Project – QR-Enabled Digital Health Record Platform

**Developer:** IT22035912 – Premarathne K A D H  
**Component Status:** Active Development  
**Version:** 0.1.0  
**Last Updated:** January 2026  

A secure, QR-based digital health record platform designed for fast emergency access to critical patient information, especially in low-resource ambulance and rural settings.

---

## 🎯 Overview

In Sri Lanka, emergency treatment can be delayed because key patient details are stored in manual/paper records. This component provides a digital patient profile that can be accessed instantly by scanning a unique QR code, while maintaining strong security and privacy.

This is an **individual component** under the group project:  
**Smart Traffic Signal Prioritization for Ambulances with IoT and Fallback Routing.**

---

## 🚨 Problem Statement

**How can we enable first responders to access critical patient information quickly and securely during emergencies, even with low network connectivity and limited device resources?**

---

## ✨ Key Features

### 1) Emergency QR Record Access
- Digitizes critical emergency info: blood group, allergies, chronic diseases, medications, emergency contact  
- Generates a unique QR code linked to the patient’s verified digital record  
- Instant QR scan → immediate access for authorized responders  

### 2) Security & Privacy
- AES encryption for sensitive medical data  
- Secure login for first responders  
- Role-based access control (only authorized personnel can view emergency data)  
- Audit logs to record QR scans and data retrievals (who/when/what)  

### 3) Low-Resource Friendly Design
- Supports offline/low-network QR scanning  
- Works with basic smartphone camera + 3G/4G connectivity  
- Lightweight stack suitable for rural and urban environments  

### 4) Report Upload + Summary (Extended Feature)
- Patients can upload medical reports (e.g., blood/urine/lab reports)  
- System generates monthly/period summaries of key changes and trends  

### 5) Health Trend Prediction (Extended Feature)
- Uses uploaded history to predict future health risk/trends  
- Provides early warnings to support preventive action  

> **Note:** “Extended features” are optional enhancements built on top of the core QR emergency access module.

---

## 🔬 Technical Approach

### Core Workflow (Emergency Access)
1. Patient Profile Creation/Update  
2. AES Encrypt Medical Data  
3. Generate Unique QR Code  
4. QR Scan by First Responder  
5. Secure Login + Role Validation  
6. Retrieve & Decrypt Record  
7. Show Emergency Summary + Log Access  

### Report Summary & Prediction (Extended)
1. Report Upload (PDF/Image/Text)  
2. Extract Key Values / Trends  
3. Generate Monthly Summary  
4. ML Prediction (Risk/Trend)  
5. Early Warning + Recommendations  

---

## 🧰 Technology Stack

- **Frontend (Mobile):** Flutter  
- **Database + Auth:** Firebase (Database + Authentication)  
- **QR Tools:** QRCode.js / qr-code.js (QR generation & scanning)  
- **Backend:** Node.js + Express (API, validation, security checks)  

---

## 📌 Project Requirements

### Functional Requirements
- Allow patients to set/update electronic profiles  
- Encrypt and manage QR codes  
- Offline QR scanner supports low network connectivity  
- Authenticate first responders with secure login methods  
- Keep an access record of all QR scans and data retrievals  

### Non-Functional Requirements
- **Security:** AES encryption + secure communication  
- **Usability:** Simple GUI for emergency use  
- **Performance:** Fast access on low-resource devices  
- **Reliability:** Works in both rural and urban environments  

---

## 📊 Dataset Requirements (For Prediction Feature)

- Anonymized medical report history (lab values over time)  
- Labels/outcomes for training (e.g., risk category / trend direction)  

### Strict privacy handling
- Remove identifiers (name, NIC, phone)  
- Store only required features for training  
- Consent-based data usage  

---

## 📈 Evaluation Metrics

### Emergency Access Performance
- Scan-to-data time (latency)  
- Successful retrieval rate (with low network/offline use)  
- Usability score (ease under emergency pressure)  

### Security Validation
- Authentication correctness (authorized vs unauthorized access)  
- Data confidentiality (encrypted at rest and in transit)  
- Audit log completeness  

### Prediction Model 
- Accuracy / F1-score (classification) OR MAE/RMSE (regression)  
- Confusion matrix / error analysis  
- Reliability on unseen users  

---

## 🔮 Future Enhancements
- Offline caching + sync strategy for weak networks  
- Emergency “read-only mode” with minimal fields  
- Better report extraction (OCR + structured lab parsing)  
- Model personalization (learn user baselines)  
- Integration with ambulance workflow dashboards  

---

## 🐛 Known Limitations
- Continuous offline access requires careful caching + security tradeoffs  
- Prediction quality depends heavily on report consistency and dataset size  
- Report extraction can be challenging for scanned images with poor quality  

---

## 👤 Developer
**Premarathne K A D H (Dileeshara)** – IT22035912
