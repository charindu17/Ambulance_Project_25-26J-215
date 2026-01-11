from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware # <--- NEW IMPORT
from pydantic import BaseModel
import joblib
import pandas as pd
import sqlite3
import json
from datetime import datetime

app = FastAPI()

# --- NEW: SECURITY PERMISSIONS (CORS) ---
# This allows your HTML file to talk to this Server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all connections
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 1. SETUP DATABASE ---
def init_db():
    conn = sqlite3.connect('vet_alerts.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            pet_id TEXT,
            severity_level TEXT,
            ai_desc TEXT,
            vitals_json TEXT
        )
    ''')
    conn.commit()
    conn.close()

init_db()

# --- 2. LOAD THE BRAIN ---
try:
    model = joblib.load('vet_triage_model.pkl')
    model_columns = joblib.load('model_columns.pkl')
    print("✅ System Ready: AI & Database Loaded.")
except:
    print("❌ Error: Model files not found.")

# --- 3. DATA MODELS ---
class PetVitals(BaseModel):
    pet_id: str = "Unknown_Pet"
    temperature_c: float
    heart_rate_bpm: int
    vomiting: int
    diarrhea: int
    lethargy: int
    pain_vocalization: int
    pale_gums: int
    seizure: int
    abdominal_distension: int

# --- 4. ENDPOINT: RECEIVE & ANALYZE ---
@app.post("/predict-triage")
async def predict_triage(vitals: PetVitals):
    input_data = pd.DataFrame([{
        'Temperature_C': vitals.temperature_c,
        'Heart_Rate_BPM': vitals.heart_rate_bpm,
        'Vomiting': vitals.vomiting,
        'Diarrhea': vitals.diarrhea,
        'Lethargy': vitals.lethargy,
        'Pain_Vocalization': vitals.pain_vocalization,
        'Pale_Gums': vitals.pale_gums,
        'Seizure': vitals.seizure,
        'Abdominal_Distension': vitals.abdominal_distension
    }])
    input_data = input_data[model_columns]

    prediction = model.predict(input_data)[0]
    
    triage_map = {
        0: {"level": "GREEN", "desc": "Non-Urgent"},
        1: {"level": "YELLOW", "desc": "URGENT"},
        2: {"level": "RED", "desc": "CRITICAL EMERGENCY"}
    }
    result = triage_map.get(prediction)

    conn = sqlite3.connect('vet_alerts.db')
    c = conn.cursor()
    c.execute("INSERT INTO alerts (timestamp, pet_id, severity_level, ai_desc, vitals_json) VALUES (?, ?, ?, ?, ?)",
              (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), 
               vitals.pet_id, 
               result['level'], 
               result['desc'], 
               input_data.to_json())
              )
    conn.commit()
    conn.close()

    return {"status": "success", "triage_result": result}

# --- 5. ENDPOINT: GET ALERTS ---
@app.get("/get-active-alerts")
async def get_alerts():
    conn = sqlite3.connect('vet_alerts.db')
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    c.execute("SELECT * FROM alerts ORDER BY id DESC LIMIT 10")
    rows = c.fetchall()
    conn.close()
    return rows