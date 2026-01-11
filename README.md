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
# Dog Health Vitals Dataset

## Description
The Dog Health Vitals Dataset is a collection of recordings and vital statistics related to the health of dogs. It includes data captured during various recording sessions, providing insights into the physiological characteristics of the dogs.

The dataset is presented in CSV format, with each line representing a recording session. The CSV file contains the following columns:

- `_id`: Unique identifier for each recording session.
- `ecg_path`: Relative path to the corresponding ECG file (in WAV format).
- `duration`: Duration of the recording session (in seconds).
- `pet_id`: Unique identifier for each dog.
- `breeds`: Main breed of the dog.
- `weight`: Weight of the dog at the time of measurement (in kg).
- `age`: Age of the dog at the time of measurement (in years).
- `segments_br`: Array of dictionaries, each dict representing a breathing rate on a specific time segment of the signal. Each dict has three keys : `deb` representing the beginning of the segment (in seconds from the beginning of the signal), `fin` representing the end of the segment (in seconds from the beginning of the signal), and `value` representing the value of the breathing rate on this segment.
- `segments_hr`: Array of dictionaries, each dict representing a heart rate on a specific time segment of the signal. Each dict has three keys : `deb` representing the beginning of the segment (in seconds from the beginning of the signal), `fin` representing the end of the segment (in seconds from the beginning of the signal), and `value` representing the value of the heart rate on this segment.
- `ecg_pulses`: Array of floats, each representing the timestamp (in seconds from the beginning of the signal) of an identified heart pulse on the ECG signal.
- `bad_ecg`: Array of tuples, representing time segments of poor ECG signal quality. Each tuple has two elements, the first being the beginning of the segment (in seconds from the beginning of the signal), and the second the end of this segment (in seconds from the beginning of the signal).
  

## Data Files
The dataset archive includes the following files:

- `dataset.csv`: The main dataset file in CSV format.
- ECG waveform files, in `ecg_data` directory: The corresponding ECG waveform files referenced in the dataset. The paths to these files are provided in the `ecg_path` column of the CSV file.

## License
This dataset is made available under the [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/) license. By using this dataset, you agree to the terms and conditions specified in the license.

## Citation
If you use this dataset in your research or any other publication, please cite it as:

`Jarkoff, H., Lorre, G., & Humbert, E. (2023). Assessing the Accuracy of a Smart Collar for Dogs: Predictive Performance for Heart and Breathing Rates on a Large Scale Dataset. Preprint available on bioRxiv.`


## Contact Information
For any questions or inquiries regarding the dataset, please contact:

Invoxia Research
<br>
research@invoxia.com
<br>
Invoxia, 8 Esp. de la Manufacture, 92130 Issy-les-Moulineaux, France
# Welcome to your Expo app 👋

This is an [Expo](https://expo.dev) project created with [`create-expo-app`](https://www.npmjs.com/package/create-expo-app).

## Get started

1. Install dependencies

   ```bash
   npm install
   ```

2. Start the app

   ```bash
   npx expo start
   ```

In the output, you'll find options to open the app in a

- [development build](https://docs.expo.dev/develop/development-builds/introduction/)
- [Android emulator](https://docs.expo.dev/workflow/android-studio-emulator/)
- [iOS simulator](https://docs.expo.dev/workflow/ios-simulator/)
- [Expo Go](https://expo.dev/go), a limited sandbox for trying out app development with Expo

You can start developing by editing the files inside the **app** directory. This project uses [file-based routing](https://docs.expo.dev/router/introduction).

## Get a fresh project

When you're ready, run:

```bash
npm run reset-project
```

This command will move the starter code to the **app-example** directory and create a blank **app** directory where you can start developing.

## Learn more

To learn more about developing your project with Expo, look at the following resources:

- [Expo documentation](https://docs.expo.dev/): Learn fundamentals, or go into advanced topics with our [guides](https://docs.expo.dev/guides).
- [Learn Expo tutorial](https://docs.expo.dev/tutorial/introduction/): Follow a step-by-step tutorial where you'll create a project that runs on Android, iOS, and the web.

## Join the community

Join our community of developers creating universal apps.

- [Expo on GitHub](https://github.com/expo/expo): View our open source platform and contribute.
- [Discord community](https://chat.expo.dev): Chat with Expo users and ask questions.
