# Eye Aspect Ratio (EAR) Drowsiness Detection System

## Overview

This system detects drowsiness by analyzing eye closure patterns in images using the Eye Aspect Ratio (EAR) metric. It leverages MediaPipe's Face Mesh for facial landmark detection and calculates whether eyes are open or closed based on geometric measurements.

## Features

- Real-time eye aspect ratio calculation
- Drowsiness detection using consecutive frame analysis
- Support for batch image processing
- MediaPipe Face Mesh integration for accurate landmark detection
- Configurable threshold and frame count parameters

## Requirements

```bash
pip install opencv-python mediapipe numpy
```

## Dependencies

- **OpenCV (cv2)**: Image processing and manipulation
- **MediaPipe**: Facial landmark detection
- **NumPy**: Numerical computations

## How It Works

### Eye Aspect Ratio (EAR)

The EAR is calculated using six facial landmarks around each eye:

```
EAR = (||p2 - p6|| + ||p3 - p5||) / (2 * ||p1 - p4||)
```

Where:
- p1-p6 are the eye landmark coordinates
- Vertical distances (numerator) increase when eyes are open
- Horizontal distance (denominator) remains relatively constant

### Drowsiness Detection Logic

1. **Threshold**: EAR < 0.25 indicates closed eyes
2. **Consecutive Frames**: 15 consecutive frames with closed eyes triggers drowsiness alert
3. **Reset**: Counter resets when eyes open (EAR ≥ threshold)

## Configuration Parameters

```python
EYE_AR_THRESH = 0.25          # EAR threshold for closed eyes
EYE_AR_CONSEC_FRAMES = 15     # Consecutive frames needed for drowsiness
```

### Tuning Guidelines

- **Lower threshold** (0.20-0.23): More sensitive, may trigger false positives
- **Higher threshold** (0.26-0.30): Less sensitive, may miss drowsiness
- **Fewer frames** (10-12): Faster detection, more false alarms
- **More frames** (18-20): Slower detection, fewer false alarms

## Usage

### Basic Example

```python
# List of image paths to analyze
image_paths = [
    "image1.jpg",
    "image2.jpg",
    "image3.jpg",
    # Add more images...
]

# Run drowsiness detection
results, status = test_drowsiness_on_images(image_paths)

# Display results
for img_path, state, ear_value in results:
    print(f"{img_path}: {state} (EAR: {ear_value})")

print(f"\nFinal Status: {status}")
```

### Expected Output

```
image1.jpg: EYES OPEN (EAR: 0.342)
image2.jpg: EYES OPEN (EAR: 0.315)
image3.jpg: EYES CLOSED (EAR: 0.198)
image4.jpg: EYES CLOSED (EAR: 0.205)
...
Final Status: DROWSY
```

## Function Reference

### `calculate_EAR(landmarks, eye_indices, w, h)`

Calculates the Eye Aspect Ratio for one eye.

**Parameters:**
- `landmarks`: MediaPipe face landmarks
- `eye_indices`: List of 6 landmark indices for the eye
- `w, h`: Image width and height

**Returns:** Float value representing the EAR

### `test_drowsiness_on_images(image_paths)`

Processes a sequence of images to detect drowsiness.

**Parameters:**
- `image_paths`: List of image file paths

**Returns:**
- `results`: List of tuples (image_path, state, EAR_value)
- `final_status`: "DROWSY" or "AWAKE"

## Landmark Indices

- **Left Eye**: [362, 385, 387, 263, 373, 380]
- **Right Eye**: [33, 160, 158, 133, 153, 144]

These indices correspond to MediaPipe's 478-point face mesh landmarks.

## Limitations

- **Lighting Conditions**: Poor lighting may affect detection accuracy
- **Face Angle**: Works best with frontal faces (±30 degrees)
- **Glasses**: May interfere with landmark detection
- **Image Quality**: Requires clear, reasonably high-resolution images
- **Static Analysis**: Simulates video by processing image sequences

## Extending to Real-Time Video

To adapt this for live video:

```python
cap = cv2.VideoCapture(0)
drowsy_counter = 0

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Process frame
    h, w, _ = frame.shape
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = mp_face_mesh.process(rgb)
    
    if result.multi_face_landmarks:
        face = result.multi_face_landmarks[0]
        left_ear = calculate_EAR(face.landmark, LEFT_EYE, w, h)
        right_ear = calculate_EAR(face.landmark, RIGHT_EYE, w, h)
        avg_ear = (left_ear + right_ear) / 2.0
        
        if avg_ear < EYE_AR_THRESH:
            drowsy_counter += 1
        else:
            drowsy_counter = 0
        
        if drowsy_counter >= EYE_AR_CONSEC_FRAMES:
            cv2.putText(frame, "DROWSY!", (50, 50), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
    
    cv2.imshow('Drowsiness Detection', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

## Troubleshooting

**No face detected:**
- Ensure good lighting conditions
- Check if face is fully visible and frontal
- Verify image file path is correct

**Inaccurate detection:**
- Adjust `EYE_AR_THRESH` based on testing
- Modify `EYE_AR_CONSEC_FRAMES` for your use case
- Test with different lighting conditions

**Performance issues:**
- Reduce image resolution before processing
- Use `static_image_mode=False` for video
- Consider using `max_num_faces=1` parameter

## References

- [MediaPipe Face Mesh](https://google.github.io/mediapipe/solutions/face_mesh.html)
- Soukupová, Tereza, and Jan Čech. "Real-time eye blink detection using facial landmarks." 21st computer vision winter workshop. 2016.

## License

This code is provided as-is for educational and research purposes.

## Author

For questions or contributions, please open an issue or pull request.