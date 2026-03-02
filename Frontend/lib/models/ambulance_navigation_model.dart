class LocationPoint {
  final double? lat;
  final double? lng;

  LocationPoint({this.lat, this.lng});

  factory LocationPoint.fromMap(Map<String, dynamic>? map) {
    if (map == null) return LocationPoint();
    return LocationPoint(
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {if (lat != null) 'lat': lat, if (lng != null) 'lng': lng};
  }
}

class AmbulanceNavigation {
  final int? id;
  final int? driverId;
  final LocationPoint? startLocation;
  final LocationPoint? endLocation;
  final String? vehicleNumber;
  final String? status;
  final String? createdAt;

  AmbulanceNavigation({
    this.id,
    this.driverId,
    this.startLocation,
    this.endLocation,
    this.vehicleNumber,
    this.status,
    this.createdAt,
  });

  factory AmbulanceNavigation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AmbulanceNavigation();
    return AmbulanceNavigation(
      id: map['id'] as int?,
      driverId: map['driver_id'] as int?,
      startLocation: map['start_location'] != null
          ? LocationPoint.fromMap(
              map['start_location'] as Map<String, dynamic>?,
            )
          : null,
      endLocation: map['end_location'] != null
          ? LocationPoint.fromMap(map['end_location'] as Map<String, dynamic>?)
          : null,
      vehicleNumber: map['vehicle_number'] as String?,
      status: map['status'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (driverId != null) 'driver_id': driverId,
      if (startLocation != null) 'start_location': startLocation?.toMap(),
      if (endLocation != null) 'end_location': endLocation?.toMap(),
      if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
