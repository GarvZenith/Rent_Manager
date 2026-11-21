enum TenantStatus {
  active,
  noticePeriod,
  inactive,
}

/// Tenant entity representing an occupant in the PG or flat
class TenantModel {
  final String id;
  final String fullName;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? guardianName;
  final String? guardianPhone;
  final String? workplaceOrCollege;
  final String idProofType; // e.g. 'Aadhaar', 'College ID'
  final String? idProofNumber;
  final String? idProofUrl;
  final TenantStatus status;
  final DateTime createdAt;

  const TenantModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.guardianName,
    this.guardianPhone,
    this.workplaceOrCollege,
    this.idProofType = 'Aadhaar',
    this.idProofNumber,
    this.idProofUrl,
    this.status = TenantStatus.active,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'email': email,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'workplaceOrCollege': workplaceOrCollege,
      'idProofType': idProofType,
      'idProofNumber': idProofNumber,
      'idProofUrl': idProofUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      alternatePhone: json['alternatePhone'] as String?,
      email: json['email'] as String?,
      guardianName: json['guardianName'] as String?,
      guardianPhone: json['guardianPhone'] as String?,
      workplaceOrCollege: json['workplaceOrCollege'] as String?,
      idProofType: json['idProofType'] as String? ?? 'Aadhaar',
      idProofNumber: json['idProofNumber'] as String?,
      idProofUrl: json['idProofUrl'] as String?,
      status: TenantStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TenantStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  TenantModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? alternatePhone,
    String? email,
    String? guardianName,
    String? guardianPhone,
    String? workplaceOrCollege,
    String? idProofType,
    String? idProofNumber,
    String? idProofUrl,
    TenantStatus? status,
    DateTime? createdAt,
  }) {
    return TenantModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      workplaceOrCollege: workplaceOrCollege ?? this.workplaceOrCollege,
      idProofType: idProofType ?? this.idProofType,
      idProofNumber: idProofNumber ?? this.idProofNumber,
      idProofUrl: idProofUrl ?? this.idProofUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
