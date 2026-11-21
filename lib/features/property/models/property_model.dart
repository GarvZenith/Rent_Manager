/// Property entity representing a PG building, hostel, or independent flat
class PropertyModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final int defaultRentDueDay; // 1 to 28
  final double defaultElectricityRate; // ₹ per unit (kWh)
  final double defaultLateFeePerDay;
  final String? upiVpa; // e.g., 'sharmaji@oksbi'
  final String? upiAccountName; // e.g., 'Ramesh Sharma'
  final DateTime createdAt;

  const PropertyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.defaultRentDueDay = 1,
    this.defaultElectricityRate = 10.0,
    this.defaultLateFeePerDay = 0.0,
    this.upiVpa,
    this.upiAccountName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'defaultRentDueDay': defaultRentDueDay,
      'defaultElectricityRate': defaultElectricityRate,
      'defaultLateFeePerDay': defaultLateFeePerDay,
      'upiVpa': upiVpa,
      'upiAccountName': upiAccountName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      defaultRentDueDay: json['defaultRentDueDay'] as int? ?? 1,
      defaultElectricityRate: (json['defaultElectricityRate'] as num?)?.toDouble() ?? 10.0,
      defaultLateFeePerDay: (json['defaultLateFeePerDay'] as num?)?.toDouble() ?? 0.0,
      upiVpa: json['upiVpa'] as String?,
      upiAccountName: json['upiAccountName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  PropertyModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? pincode,
    int? defaultRentDueDay,
    double? defaultElectricityRate,
    double? defaultLateFeePerDay,
    String? upiVpa,
    String? upiAccountName,
    DateTime? createdAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      defaultRentDueDay: defaultRentDueDay ?? this.defaultRentDueDay,
      defaultElectricityRate: defaultElectricityRate ?? this.defaultElectricityRate,
      defaultLateFeePerDay: defaultLateFeePerDay ?? this.defaultLateFeePerDay,
      upiVpa: upiVpa ?? this.upiVpa,
      upiAccountName: upiAccountName ?? this.upiAccountName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
