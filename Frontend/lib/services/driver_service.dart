import '../models/models.dart';
import 'api_client.dart';

class DriverService {
  final ApiClient _client;

  DriverService({ApiClient? client}) : _client = client ?? ApiClient();

  // ============ Driver Auth ============

  Future<DriverAuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String vehicleNumber,
    required String nic,
    String? staffId,
  }) async {
    final response = await _client.post(
      '/auth/driver/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'vehicle_number': vehicleNumber,
        'nic': nic,
        if (staffId != null) 'staff_id': staffId,
      },
    );

    return DriverAuthResponse.fromMap(response);
  }

  Future<DriverAuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/driver/login',
      body: {'email': email, 'password': password},
    );

    return DriverAuthResponse.fromMap(response);
  }

  // ============ Driver CRUD ============

  Future<DriverResponse> getDriver(int driverId) async {
    final response = await _client.get('/drivers/$driverId');
    return DriverResponse.fromMap(response);
  }

  Future<DriversListResponse> getAllDrivers() async {
    final response = await _client.get('/drivers');
    return DriversListResponse.fromMap(response);
  }

  Future<DriverResponse> updateDriver(
    int driverId, {
    String? name,
    String? vehicleNumber,
    String? password,
    String? nic,
    String? staffId,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (vehicleNumber != null) body['vehicle_number'] = vehicleNumber;
    if (password != null) body['password'] = password;
    if (nic != null) body['nic'] = nic;
    if (staffId != null) body['staff_id'] = staffId;

    final response = await _client.put('/drivers/$driverId', body: body);
    return DriverResponse.fromMap(response);
  }

  Future<DeleteResponse> deleteDriver(int driverId) async {
    final response = await _client.delete('/drivers/$driverId');
    return DeleteResponse.fromMap(response);
  }
}
