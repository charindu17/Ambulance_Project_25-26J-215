# Drowsiness Detection System
**IT22366290**

## What It Does
Detects if someone is getting drowsy by monitoring their eyes. When eyes stay closed for too long, it triggers an alert.

## Install Required Packages
```bash
pip install opencv-python mediapipe numpy
```

## Quick Start
```python
from drowsiness_detector import test_drowsiness_on_images

# Add your image paths
images = ["photo1.jpg", "photo2.jpg", "photo3.jpg"]

# Run detection
results, status = test_drowsiness_on_images(images)

# Check results
print(f"Status: {status}")
```

## How It Works
The system uses **Eye Aspect Ratio (EAR)** to measure how open your eyes are:

- **Eyes open**: EAR around 0.3
- **Eyes closed**: EAR around 0.1-0.2
- **Alert triggered**: Eyes closed for 15 frames in a row

## Settings You Can Change
```python
EYE_AR_THRESH = 0.25          # When to consider eyes "closed"
EYE_AR_CONSEC_FRAMES = 15     # How many frames before alerting
```

Want faster detection? Lower the frame count to 10.
Getting false alarms? Increase threshold to 0.27 or frame count to 20.

## Main Functions

**calculate_EAR(landmarks, eye_indices, w, h)**
- Measures how open one eye is
- Returns a number (higher = more open)

**test_drowsiness_on_images(image_paths)**
- Checks a series of images
- Returns detection results and final status

## Common Issues

**"No face detected"**
- Make sure there's enough light
- Face the camera directly
- Check image file paths

**"False alarms"**
- Increase `EYE_AR_THRESH` to 0.27
- Increase `EYE_AR_CONSEC_FRAMES` to 20
- Adjust lighting in room

**"Not detecting when drowsy"**
- Lower `EYE_AR_THRESH` to 0.23
- Lower `EYE_AR_CONSEC_FRAMES` to 12

## Limitations
- Needs decent lighting
- Works best when looking at camera
- Sunglasses will interfere
- Requires clear face view

## Project Info
This is for stress and fatigue detection using computer vision.

**Student ID**: IT22366290
