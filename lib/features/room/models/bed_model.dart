/// Bed entity for tracking sharing beds inside a PG/Hostel room
class BedModel {
  final String id;
  final String roomId;
  final String bedLabel; // 'Bed A', 'Bed B', 'Single'
  final bool isOccupied;
  final String? currentTenantId;

  const BedModel({
    required this.id,
    required this.roomId,
    required this.bedLabel,
    this.isOccupied = false,
    this.currentTenantId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'bedLabel': bedLabel,
      'isOccupied': isOccupied,
      'currentTenantId': currentTenantId,
    };
  }

  factory BedModel.fromJson(Map<String, dynamic> json) {
    return BedModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      bedLabel: json['bedLabel'] as String,
      isOccupied: json['isOccupied'] as bool? ?? false,
      currentTenantId: json['currentTenantId'] as String?,
    );
  }

  BedModel copyWith({
    String? id,
    String? roomId,
    String? bedLabel,
    bool? isOccupied,
    String? currentTenantId,
  }) {
    return BedModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      bedLabel: bedLabel ?? this.bedLabel,
      isOccupied: isOccupied ?? this.isOccupied,
      currentTenantId: currentTenantId ?? this.currentTenantId,
    );
  }
}
