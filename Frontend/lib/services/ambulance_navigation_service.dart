import '../models/models.dart';
import 'api_client.dart';

class AmbulanceNavigationService {
  final ApiClient _client;

  AmbulanceNavigationService({ApiClient? client})
      : _client = client ?? ApiClient();

  // ============ Navigation CRUD ============

  Future<AmbulanceNavigationResponse> createNavigation({
    required int driverId,
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    String? vehicleNumber,
  }) async {
    final Map<String, dynamic> body = {
      'driver_id': driverId,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
    };
    if (vehicleNumber != null) body['vehicle_number'] = vehicleNumber;

    final response = await _client.post('/ambulance-navigation', body: body);
    return AmbulanceNavigationResponse.fromMap(response);
  }

  Future<AmbulanceNavigationResponse> getNavigation(int navigationId) async {
    final response = await _client.get('/ambulance-navigation/$navigationId');
    return AmbulanceNavigationResponse.fromMap(response);
  }

  Future<AmbulanceNavigationsListResponse> getDriverNavigations(
    int driverId,
  ) async {
    final response = await _client.get('/ambulance-navigation/driver/$driverId');
    return AmbulanceNavigationsListResponse.fromMap(response);
  }

  Future<AmbulanceNavigationResponse> updateNavigation(
    int navigationId, {
    double? endLatitude,
    double? endLongitude,
    String? vehicleNumber,
  }) async {
    final Map<String, dynamic> body = {};
    if (endLatitude != null) body['end_latitude'] = endLatitude;
    if (endLongitude != null) body['end_longitude'] = endLongitude;
    if (vehicleNumber != null) body['vehicle_number'] = vehicleNumber;

    final response = await _client.put(
      '/ambulance-navigation/$navigationId',
      body: body,
    );
    return AmbulanceNavigationResponse.fromMap(response);
  }

  Future<AmbulanceNavigationResponse> updateStatus(
    int navigationId, {
    required String status,
  }) async {
    final response = await _client.patch(
      '/ambulance-navigation/$navigationId/status',
      body: {'status': status},
    );
    return AmbulanceNavigationResponse.fromMap(response);
  }

  Future<DeleteResponse> deleteNavigation(int navigationId) async {
    final response = await _client.delete(
      '/ambulance-navigation/$navigationId',
    );
    return DeleteResponse.fromMap(response);
  }
}
