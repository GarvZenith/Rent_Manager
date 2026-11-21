import 'bed_model.dart';

enum RoomSharingType {
  single,
  doubleSharing,
  tripleSharing,
  fourPlus,
  fullFlat,
}

/// Room entity representing a room or flat unit in a PG/Hostel
class RoomModel {
  final String id;
  final String propertyId;
  final String roomNumber;
  final int floorNumber;
  final RoomSharingType sharingType;
  final double baseRentPerBed;
  final String? subMeterNumber;
  final double currentMeterReading;
  final DateTime? lastMeterReadingDate;
  final List<BedModel> beds;

  const RoomModel({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    this.floorNumber = 0,
    this.sharingType = RoomSharingType.single,
    required this.baseRentPerBed,
    this.subMeterNumber,
    this.currentMeterReading = 0.0,
    this.lastMeterReadingDate,
    this.beds = const [],
  });

  /// True if all beds in the room are occupied
  bool get isFullyOccupied => beds.isNotEmpty && beds.every((b) => b.isOccupied);

  /// True if at least one bed is empty
  bool get hasVacantBed => beds.isEmpty || beds.any((b) => !b.isOccupied);

  /// Total number of occupied beds
  int get occupiedBedCount => beds.where((b) => b.isOccupied).length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'roomNumber': roomNumber,
      'floorNumber': floorNumber,
      'sharingType': sharingType.name,
      'baseRentPerBed': baseRentPerBed,
      'subMeterNumber': subMeterNumber,
      'currentMeterReading': currentMeterReading,
      'lastMeterReadingDate': lastMeterReadingDate?.toIso8601String(),
      'beds': beds.map((b) => b.toJson()).toList(),
    };
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      roomNumber: json['roomNumber'] as String,
      floorNumber: json['floorNumber'] as int? ?? 0,
      sharingType: RoomSharingType.values.firstWhere(
        (e) => e.name == json['sharingType'],
        orElse: () => RoomSharingType.single,
      ),
      baseRentPerBed: (json['baseRentPerBed'] as num).toDouble(),
      subMeterNumber: json['subMeterNumber'] as String?,
      currentMeterReading: (json['currentMeterReading'] as num?)?.toDouble() ?? 0.0,
      lastMeterReadingDate: json['lastMeterReadingDate'] != null
          ? DateTime.parse(json['lastMeterReadingDate'] as String)
          : null,
      beds: (json['beds'] as List<dynamic>?)
              ?.map((e) => BedModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  RoomModel copyWith({
    String? id,
    String? propertyId,
    String? roomNumber,
    int? floorNumber,
    RoomSharingType? sharingType,
    double? baseRentPerBed,
    String? subMeterNumber,
    double? currentMeterReading,
    DateTime? lastMeterReadingDate,
    List<BedModel>? beds,
  }) {
    return RoomModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      roomNumber: roomNumber ?? this.roomNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      sharingType: sharingType ?? this.sharingType,
      baseRentPerBed: baseRentPerBed ?? this.baseRentPerBed,
      subMeterNumber: subMeterNumber ?? this.subMeterNumber,
      currentMeterReading: currentMeterReading ?? this.currentMeterReading,
      lastMeterReadingDate: lastMeterReadingDate ?? this.lastMeterReadingDate,
      beds: beds ?? this.beds,
    );
  }
}
