import * as Location from 'expo-location';
import { Accelerometer, Gyroscope } from 'expo-sensors';
import React, { useEffect, useRef, useState } from 'react';
import { Alert, Platform, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
// Using Legacy file system to prevent crash on Android (Expo SDK 54 fix)
import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';

export default function App() {
  // --- STATE (For Visuals) ---
  const [isRecording, setIsRecording] = useState(false);
  const [position, setPosition] = useState('Mount (Fixed)'); 
  const [uiLabel, setUiLabel] = useState('Cruising'); // Used ONLY for button colors
  const [dataCount, setDataCount] = useState(0);
  const [gpsStatus, setGpsStatus] = useState('Waiting...');
  
  // --- REFS (The "Live" Data Stream) ---
  // 1. We use a REF for the label. This allows the sensor listener to read the 
  //    LATEST value instantly without needing to restart the recording function.
  const currentLabelRef = useRef('Cruising');
  
  const dataRef = useRef([]);
  const latestGps = useRef({ lat: 0, lon: 0, speed: 0, alt: 0 });
  const subscriptionAcc = useRef(null);
  const subscriptionLoc = useRef(null);

  // --- SETUP ON START ---
  useEffect(() => {
    setupPermissions();
    // 50Hz Update Rate (20ms) is standard for driver behavior analysis
    Accelerometer.setUpdateInterval(20);
    Gyroscope.setUpdateInterval(20);
  }, []);

  const setupPermissions = async () => {
    let { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert('Permission Denied', 'GPS is required for this app.');
      return;
    }

    // Watch GPS constantly so we always have speed ready
    subscriptionLoc.current = await Location.watchPositionAsync(
      {
        accuracy: Location.Accuracy.BestForNavigation,
        timeInterval: 1000, 
        distanceInterval: 1, 
      },
      (loc) => {
        latestGps.current = {
          lat: loc.coords.latitude,
          lon: loc.coords.longitude,
          speed: loc.coords.speed,
          alt: loc.coords.altitude
        };
        setGpsStatus(`GPS Active: ${loc.coords.speed?.toFixed(1) || 0} m/s`);
      }
    );
  };

  // --- THE "HOT SWAP" FUNCTION ---
  // This updates the visual button color AND the data reference instantly
  const switchLabel = (newLabel) => {
    setUiLabel(newLabel);               // Update Screen Color (React State)
    currentLabelRef.current = newLabel; // Update Data Stream (Ref)
  };

  // --- RECORDING LOGIC ---
  const toggleRecording = async () => {
    if (isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  };

  const startRecording = () => {
    dataRef.current = []; 
    setIsRecording(true);

    // Subscribe to Accelerometer (The "Heartbeat" of the recorder)
    subscriptionAcc.current = Accelerometer.addListener(accData => {
      const timestamp = Date.now();
      
      const point = {
        ts: timestamp,
        // CRITICAL FIX: We read .current, so it gets the live button press instantly
        label: currentLabelRef.current, 
        pos: position,
        acc_x: accData.x,
        acc_y: accData.y,
        acc_z: accData.z,
        gps_speed: latestGps.current.speed,
        gps_lat: latestGps.current.lat,
        gps_lon: latestGps.current.lon
      };
      
      dataRef.current.push(point);
      
      // Update UI count every 50 points (approx 1 second) to save battery/performance
      if (dataRef.current.length % 50 === 0) {
        setDataCount(dataRef.current.length);
      }
    });
  };

  const stopRecording = () => {
    setIsRecording(false);
    if (subscriptionAcc.current) subscriptionAcc.current.remove();
    saveAndShare();
  };

  // --- SAVING CSV ---
  const saveAndShare = async () => {
    const header = "timestamp,label,phone_position,acc_x,acc_y,acc_z,gps_speed,latitude,longitude\n";
    const rows = dataRef.current.map(d => 
      `${d.ts},${d.label},${d.pos},${d.acc_x},${d.acc_y},${d.acc_z},${d.gps_speed},${d.gps_lat},${d.gps_lon}`
    ).join("\n");

    const csvString = header + rows;
    const filename = FileSystem.documentDirectory + `trip_${Date.now()}.csv`;
    
    // Using Legacy encoding 'utf8' string to avoid SDK 54 crash
    await FileSystem.writeAsStringAsync(filename, csvString, { encoding: 'utf8' });

    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(filename);
    } else {
      Alert.alert("Error", "Sharing is not available on this device");
    }
  };

  // --- UI RENDERING ---
  return (
    <View style={styles.container}>
      <Text style={styles.header}>MoveOver Collector</Text>
      
      {/* STATUS PANEL */}
      <View style={styles.panel}>
        <Text style={styles.statusText}>GPS: {gpsStatus}</Text>
        <Text style={styles.statusText}>Points: {dataCount}</Text>
        <Text style={[styles.statusText, {color: isRecording ? '#e74c3c' : '#2ecc71', marginTop: 5}]}>
           STATUS: {isRecording ? "🔴 RECORDING..." : "⚪ IDLE"}
        </Text>
      </View>

      <ScrollView>
        {/* 1. POSITION SELECTOR */}
        <Text style={styles.sectionTitle}>1. Phone Position</Text>
        <View style={styles.row}>
          {['Mount (Fixed)', 'Cup Holder', 'Bag/Pocket'].map((p) => (
            <TouchableOpacity 
              key={p} 
              style={[styles.btnSmall, position === p && styles.btnSelected]}
              onPress={() => setPosition(p)}
              disabled={isRecording}
            >
              <Text style={styles.btnTextSmall}>{p}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* 2. LIVE ACTION BUTTONS */}
        <Text style={styles.sectionTitle}>2. Live Actions (Tap while driving)</Text>
        <View style={styles.grid}>
          {/* CRUISING (RESET) */}
          <TouchableOpacity 
            style={[styles.btnAction, uiLabel === 'Cruising' && styles.btnActionActive]}
            onPress={() => switchLabel('Cruising')}
          >
            <Text style={styles.btnText}>🚗 CRUISING (Reset)</Text>
          </TouchableOpacity>

          {/* BRAKING */}
          <TouchableOpacity 
            style={[styles.btnAction, uiLabel === 'Braking' && styles.btnActionActive, {backgroundColor: '#c0392b'}]}
            onPress={() => switchLabel('Braking')}
          >
            <Text style={styles.btnText}>⚠️ BRAKING</Text>
          </TouchableOpacity>

          {/* TURNING ROW */}
          <View style={styles.row}>
             <TouchableOpacity 
              style={[styles.btnAction, uiLabel === 'Lane Left' && styles.btnActionActive, {flex:1, marginRight:5, backgroundColor: '#2980b9'}]}
              onPress={() => switchLabel('Lane Left')}
            >
              <Text style={styles.btnText}>⬅️ LEFT TURN</Text>
            </TouchableOpacity>
            <TouchableOpacity 
              style={[styles.btnAction, uiLabel === 'Lane Right' && styles.btnActionActive, {flex:1, marginLeft:5, backgroundColor: '#2980b9'}]}
              onPress={() => switchLabel('Lane Right')}
            >
              <Text style={styles.btnText}>RIGHT TURN ➡️</Text>
            </TouchableOpacity>
          </View>

          {/* AMBULANCE SIMULATION */}
          <TouchableOpacity 
            style={[styles.btnAction, uiLabel === 'Pullover' && styles.btnActionActive, {backgroundColor: '#27ae60'}]}
            onPress={() => switchLabel('Pullover')}
          >
            <Text style={styles.btnText}>🚑 PULLING OVER</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      {/* MAIN RECORD BUTTON */}
      <TouchableOpacity 
        style={[styles.btnRecord, isRecording && styles.btnStop]}
        onPress={toggleRecording}
      >
        <Text style={styles.btnRecordText}>
          {isRecording ? "STOP & SAVE CSV" : "START NEW TRIP"}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#2c3e50', padding: 20, paddingTop: 50 },
  header: { fontSize: 24, fontWeight: 'bold', color: 'white', marginBottom: 10, textAlign: 'center' },
  panel: { backgroundColor: '#34495e', padding: 15, borderRadius: 10, marginBottom: 20, borderWidth: 1, borderColor: '#465f75' },
  statusText: { color: '#bdc3c7', fontSize: 14, fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace', fontWeight: 'bold' },
  sectionTitle: { color: 'white', fontSize: 14, marginTop: 5, marginBottom: 5, textTransform: 'uppercase', letterSpacing: 1, opacity: 0.8 },
  row: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 10 },
  grid: { gap: 10, marginBottom: 20 },
  btnSmall: { flex: 1, backgroundColor: '#7f8c8d', padding: 10, borderRadius: 5, marginHorizontal: 2, alignItems: 'center' },
  btnSelected: { backgroundColor: '#f39c12' },
  btnTextSmall: { color: 'white', fontSize: 10, fontWeight: 'bold' },
  btnAction: { backgroundColor: '#7f8c8d', padding: 18, borderRadius: 10, alignItems: 'center', marginBottom: 5, elevation: 3 },
  btnActionActive: { borderWidth: 4, borderColor: 'white', transform: [{scale: 1.02}], elevation: 10 },
  btnText: { color: 'white', fontWeight: 'bold', fontSize: 16 },
  btnRecord: { backgroundColor: '#3498db', padding: 20, borderRadius: 15, alignItems: 'center', marginTop: 'auto', shadowColor: '#000', shadowOffset: {width: 0, height: 4}, shadowOpacity: 0.3, shadowRadius: 4.65, elevation: 8 },
  btnStop: { backgroundColor: '#e74c3c' },
  btnRecordText: { color: 'white', fontSize: 20, fontWeight: '900' },
});