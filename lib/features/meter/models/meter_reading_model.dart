/// Sub-meter reading entity tracking electrical consumption per room
class MeterReadingModel {
  final String id;
  final String roomId;
  final DateTime readingDate;
  final double previousReading;
  final double currentReading;
  final double ratePerUnit; // in ₹ (e.g., 10.00)
  final String? meterPhotoUrl;
  final String? notes;

  const MeterReadingModel({
    required this.id,
    required this.roomId,
    required this.readingDate,
    required this.previousReading,
    required this.currentReading,
    required this.ratePerUnit,
    this.meterPhotoUrl,
    this.notes,
  });

  /// Units consumed during this billing cycle (Current - Previous)
  double get unitsConsumed => currentReading - previousReading;

  /// Total electricity bill amount (Units * Rate per unit)
  double get totalAmount => unitsConsumed * ratePerUnit;

  /// Validation: Ensures current reading is never lower than previous
  bool get isValid => currentReading >= previousReading;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'readingDate': readingDate.toIso8601String(),
      'previousReading': previousReading,
      'currentReading': currentReading,
      'ratePerUnit': ratePerUnit,
      'unitsConsumed': unitsConsumed,
      'totalAmount': totalAmount,
      'meterPhotoUrl': meterPhotoUrl,
      'notes': notes,
    };
  }

  factory MeterReadingModel.fromJson(Map<String, dynamic> json) {
    return MeterReadingModel(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      readingDate: DateTime.parse(json['readingDate'] as String),
      previousReading: (json['previousReading'] as num).toDouble(),
      currentReading: (json['currentReading'] as num).toDouble(),
      ratePerUnit: (json['ratePerUnit'] as num).toDouble(),
      meterPhotoUrl: json['meterPhotoUrl'] as String?,
      notes: json['notes'] as String?,
    );
  }

  MeterReadingModel copyWith({
    String? id,
    String? roomId,
    DateTime? readingDate,
    double? previousReading,
    double? currentReading,
    double? ratePerUnit,
    String? meterPhotoUrl,
    String? notes,
  }) {
    return MeterReadingModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      readingDate: readingDate ?? this.readingDate,
      previousReading: previousReading ?? this.previousReading,
      currentReading: currentReading ?? this.currentReading,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      meterPhotoUrl: meterPhotoUrl ?? this.meterPhotoUrl,
      notes: notes ?? this.notes,
    );
  }
}
