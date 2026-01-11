from flask import Flask, render_template
from flask_socketio import SocketIO
import cv2
import mediapipe as mp
import numpy as np
from rmn import RMN

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

# RMN
m = RMN()

@app.route("/")
def index():
    return render_template("index.html")

def generate_stream():
    cap = cv2.VideoCapture(0)
    frame_count = 0

    while True:
        success, frame = cap.read()
        if not success:
            break

        frame_count += 1

        # ----- YOUR EXISTING LOGIC -----
        fatigue_score = np.random.uniform(0.2, 0.9)  # Replace with EAR logic
        fatigue_level = "HIGH" if fatigue_score < 0.25 else "LOW"

        stress_level = "LOW"
        if frame_count % 5 == 0:
            roi = frame[:, 320:640]
            rmn_res = m.detect_emotion_for_single_frame(roi)
            if rmn_res:
                emo = rmn_res[0]['emo_label']
                stress_level = "HIGH" if emo in ['angry','fear'] else "LOW"

        # Send to UI
        socketio.emit("update", {
            "fatigue_score": round(fatigue_score, 2),
            "fatigue_level": fatigue_level,
            "stress_level": stress_level
        })

        socketio.sleep(0.05)

@socketio.on("start")
def start_stream():
    socketio.start_background_task(generate_stream)

if __name__ == "__main__":
    socketio.run(app, debug=True)
