class Driver {
  final int? id;
  final String? name;
  final String? email;
  final String? password;
  final String? vehicleNumber;
  final String? nic;
  final String? staffId;
  final String? createdAt;

  Driver({
    this.id,
    this.name,
    this.email,
    this.password,
    this.vehicleNumber,
    this.nic,
    this.staffId,
    this.createdAt,
  });

  factory Driver.fromMap(Map<String, dynamic>? map) {
    if (map == null) return Driver();
    return Driver(
      id: map['id'] as int?,
      name: map['name'] as String?,
      email: map['email'] as String?,
      password: map['password'] as String?,
      vehicleNumber: map['vehicle_number'] as String?,
      nic: map['nic'] as String?,
      staffId: map['staff_id'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
      if (nic != null) 'nic': nic,
      if (staffId != null) 'staff_id': staffId,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
