import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  // Keys
  static const String _patientKey = 'patient_data';
  static const String _driverKey = 'driver_data';
  static const String _driverIdKey = 'driver_id';
  static const String _isDriverLoggedInKey = 'is_driver_logged_in';
  static const String _currentNavigationIdKey = 'current_navigation_id';
  static const String _doctorKey = 'doctor_data';
  static const String _isDoctorLoggedInKey = 'is_doctor_logged_in';

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // ============ Patient Data ============

  Future<void> savePatient(Patient patient) async {
    final jsonString = jsonEncode(patient.toMap());
    await _prefs?.setString(_patientKey, jsonString);
  }

  Patient? getPatient() {
    final jsonString = _prefs?.getString(_patientKey);
    if (jsonString == null) return null;

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return Patient.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearPatient() async {
    await _prefs?.remove(_patientKey);
  }

  bool get isLoggedIn => getPatient() != null;

  // ============ Doctor Data ============

  Future<void> saveDoctor(Doctor doctor) async {
    final jsonString = jsonEncode(doctor.toMap());
    await _prefs?.setString(_doctorKey, jsonString);
    await _prefs?.setBool(_isDoctorLoggedInKey, true);
  }

  Doctor? getDoctor() {
    final jsonString = _prefs?.getString(_doctorKey);
    if (jsonString == null) return null;

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return Doctor.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  bool get isDoctorLoggedIn => _prefs?.getBool(_isDoctorLoggedInKey) ?? false;

  Future<void> clearDoctor() async {
    await _prefs?.remove(_doctorKey);
    await _prefs?.remove(_isDoctorLoggedInKey);
  }

  // ============ Driver Data ============

  Future<void> saveDriver(Driver driver) async {
    final jsonString = jsonEncode(driver.toMap());
    await _prefs?.setString(_driverKey, jsonString);
    if (driver.id != null) {
      await _prefs?.setInt(_driverIdKey, driver.id!);
    }
    await _prefs?.setBool(_isDriverLoggedInKey, true);
  }

  Driver? getDriver() {
    final jsonString = _prefs?.getString(_driverKey);
    if (jsonString == null) return null;

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return Driver.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  int? getDriverId() {
    return _prefs?.getInt(_driverIdKey);
  }

  bool get isDriverLoggedIn => _prefs?.getBool(_isDriverLoggedInKey) ?? false;

  Future<void> clearDriver() async {
    await _prefs?.remove(_driverKey);
    await _prefs?.remove(_driverIdKey);
    await _prefs?.remove(_isDriverLoggedInKey);
    await _prefs?.remove(_currentNavigationIdKey);
  }

  // ============ Navigation Data ============

  Future<void> saveCurrentNavigation(int navigationId) async {
    await _prefs?.setInt(_currentNavigationIdKey, navigationId);
  }

  int? getCurrentNavigation() {
    return _prefs?.getInt(_currentNavigationIdKey);
  }

  Future<void> clearCurrentNavigation() async {
    await _prefs?.remove(_currentNavigationIdKey);
  }

  // ============ Clear All ============

  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
