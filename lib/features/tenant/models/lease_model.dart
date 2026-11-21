/// Lease agreement linking a tenant to a room/bed with specific rent terms
class LeaseModel {
  final String id;
  final String tenantId;
  final String roomId;
  final String bedId;
  final DateTime startDate;
  final DateTime? endDate;
  final double agreedMonthlyRent;
  final double securityDepositAmount;
  final bool isSecurityDepositPaid;
  final bool isActive;
  final String? moveOutNotes;

  const LeaseModel({
    required this.id,
    required this.tenantId,
    required this.roomId,
    required this.bedId,
    required this.startDate,
    this.endDate,
    required this.agreedMonthlyRent,
    this.securityDepositAmount = 0.0,
    this.isSecurityDepositPaid = false,
    this.isActive = true,
    this.moveOutNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'roomId': roomId,
      'bedId': bedId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'agreedMonthlyRent': agreedMonthlyRent,
      'securityDepositAmount': securityDepositAmount,
      'isSecurityDepositPaid': isSecurityDepositPaid,
      'isActive': isActive,
      'moveOutNotes': moveOutNotes,
    };
  }

  factory LeaseModel.fromJson(Map<String, dynamic> json) {
    return LeaseModel(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      roomId: json['roomId'] as String,
      bedId: json['bedId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      agreedMonthlyRent: (json['agreedMonthlyRent'] as num).toDouble(),
      securityDepositAmount: (json['securityDepositAmount'] as num?)?.toDouble() ?? 0.0,
      isSecurityDepositPaid: json['isSecurityDepositPaid'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      moveOutNotes: json['moveOutNotes'] as String?,
    );
  }

  LeaseModel copyWith({
    String? id,
    String? tenantId,
    String? roomId,
    String? bedId,
    DateTime? startDate,
    DateTime? endDate,
    double? agreedMonthlyRent,
    double? securityDepositAmount,
    bool? isSecurityDepositPaid,
    bool? isActive,
    String? moveOutNotes,
  }) {
    return LeaseModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      bedId: bedId ?? this.bedId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      agreedMonthlyRent: agreedMonthlyRent ?? this.agreedMonthlyRent,
      securityDepositAmount: securityDepositAmount ?? this.securityDepositAmount,
      isSecurityDepositPaid: isSecurityDepositPaid ?? this.isSecurityDepositPaid,
      isActive: isActive ?? this.isActive,
      moveOutNotes: moveOutNotes ?? this.moveOutNotes,
    );
  }
}
