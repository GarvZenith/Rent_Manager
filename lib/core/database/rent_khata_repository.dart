import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../features/property/models/property_model.dart';
import '../../features/room/models/room_model.dart';
import '../../features/room/models/bed_model.dart';
import '../../features/tenant/models/tenant_model.dart';
import '../../features/tenant/models/lease_model.dart';
import '../../features/meter/models/meter_reading_model.dart';
import '../../features/invoice/models/invoice_model.dart';
import '../../features/payment/models/payment_model.dart';

/// Immutable state holder for the complete RentKhata offline database
class RentKhataState {
  final List<PropertyModel> properties;
  final List<RoomModel> rooms;
  final List<TenantModel> tenants;
  final List<LeaseModel> leases;
  final List<MeterReadingModel> meterReadings;
  final List<InvoiceModel> invoices;
  final List<PaymentModel> payments;

  const RentKhataState({
    this.properties = const [],
    this.rooms = const [],
    this.tenants = const [],
    this.leases = const [],
    this.meterReadings = const [],
    this.invoices = const [],
    this.payments = const [],
  });

  RentKhataState copyWith({
    List<PropertyModel>? properties,
    List<RoomModel>? rooms,
    List<TenantModel>? tenants,
    List<LeaseModel>? leases,
    List<MeterReadingModel>? meterReadings,
    List<InvoiceModel>? invoices,
    List<PaymentModel>? payments,
  }) {
    return RentKhataState(
      properties: properties ?? this.properties,
      rooms: rooms ?? this.rooms,
      tenants: tenants ?? this.tenants,
      leases: leases ?? this.leases,
      meterReadings: meterReadings ?? this.meterReadings,
      invoices: invoices ?? this.invoices,
      payments: payments ?? this.payments,
    );
  }
}

/// Offline-first repository managing all real-estate entities, calculations & balances
class RentKhataRepository extends StateNotifier<RentKhataState> {
  final Uuid _uuid = const Uuid();

  RentKhataRepository([RentKhataState? initialState])
      : super(initialState ?? const RentKhataState());

  // ===========================================================================
  // PROPERTY OPERATIONS
  // ===========================================================================
  PropertyModel addProperty({
    required String name,
    required String address,
    required String city,
    required String stateName,
    required String pincode,
    double defaultElectricityRate = 10.0,
    int defaultRentDueDay = 1,
    String? upiVpa,
    String? upiAccountName,
  }) {
    final property = PropertyModel(
      id: _uuid.v4(),
      name: name,
      address: address,
      city: city,
      state: stateName,
      pincode: pincode,
      defaultElectricityRate: defaultElectricityRate,
      defaultRentDueDay: defaultRentDueDay,
      upiVpa: upiVpa,
      upiAccountName: upiAccountName,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(properties: [...state.properties, property]);
    return property;
  }

  // ===========================================================================
  // ROOM & BED OPERATIONS
  // ===========================================================================
  RoomModel addRoom({
    required String propertyId,
    required String roomNumber,
    int floorNumber = 0,
    RoomSharingType sharingType = RoomSharingType.single,
    required double baseRentPerBed,
    String? subMeterNumber,
    double initialMeterReading = 0.0,
  }) {
    final roomId = _uuid.v4();

    // Generate beds according to sharing type
    final List<BedModel> beds = [];
    int bedCount = 1;
    if (sharingType == RoomSharingType.doubleSharing) bedCount = 2;
    if (sharingType == RoomSharingType.tripleSharing) bedCount = 3;
    if (sharingType == RoomSharingType.fourPlus) bedCount = 4;

    for (int i = 0; i < bedCount; i++) {
      final label = bedCount == 1 ? 'Single' : 'Bed ${String.fromCharCode(65 + i)}'; // Bed A, Bed B
      beds.add(BedModel(
        id: _uuid.v4(),
        roomId: roomId,
        bedLabel: label,
        isOccupied: false,
      ));
    }

    final room = RoomModel(
      id: roomId,
      propertyId: propertyId,
      roomNumber: roomNumber,
      floorNumber: floorNumber,
      sharingType: sharingType,
      baseRentPerBed: baseRentPerBed,
      subMeterNumber: subMeterNumber,
      currentMeterReading: initialMeterReading,
      lastMeterReadingDate: DateTime.now(),
      beds: beds,
    );

    state = state.copyWith(rooms: [...state.rooms, room]);
    return room;
  }

  // ===========================================================================
  // TENANT ONBOARDING & LEASE ALLOCATION
  // ===========================================================================
  ({TenantModel tenant, LeaseModel lease}) onboardTenant({
    required String roomId,
    required String bedId,
    required String fullName,
    required String phone,
    String? alternatePhone,
    String? guardianName,
    String? guardianPhone,
    String? workplaceOrCollege,
    required double agreedRent,
    double securityDeposit = 0.0,
    bool isDepositPaid = false,
  }) {
    final tenantId = _uuid.v4();
    final tenant = TenantModel(
      id: tenantId,
      fullName: fullName,
      phone: phone,
      alternatePhone: alternatePhone,
      guardianName: guardianName,
      guardianPhone: guardianPhone,
      workplaceOrCollege: workplaceOrCollege,
      createdAt: DateTime.now(),
    );

    final lease = LeaseModel(
      id: _uuid.v4(),
      tenantId: tenantId,
      roomId: roomId,
      bedId: bedId,
      startDate: DateTime.now(),
      agreedMonthlyRent: agreedRent,
      securityDepositAmount: securityDeposit,
      isSecurityDepositPaid: isDepositPaid,
      isActive: true,
    );

    // Update bed occupancy status inside the room
    final updatedRooms = state.rooms.map((room) {
      if (room.id == roomId) {
        final updatedBeds = room.beds.map((b) {
          if (b.id == bedId) {
            return b.copyWith(isOccupied: true, currentTenantId: tenantId);
          }
          return b;
        }).toList();
        return room.copyWith(beds: updatedBeds);
      }
      return room;
    }).toList();

    state = state.copyWith(
      tenants: [...state.tenants, tenant],
      leases: [...state.leases, lease],
      rooms: updatedRooms,
    );

    return (tenant: tenant, lease: lease);
  }

  // ===========================================================================
  // TENANT MOVE-OUT & SECURITY DEPOSIT SETTLEMENT
  // ===========================================================================
  void settleMoveOut({required String leaseId, String? notes}) {
    final lease = state.leases.firstWhere(
      (l) => l.id == leaseId,
      orElse: () => throw ArgumentError('Lease not found: $leaseId'),
    );

    // Free up the bed in the room
    final updatedRooms = state.rooms.map((room) {
      if (room.id == lease.roomId) {
        final updatedBeds = room.beds.map((b) {
          if (b.id == lease.bedId) {
            return b.copyWith(isOccupied: false, currentTenantId: null);
          }
          return b;
        }).toList();
        return room.copyWith(beds: updatedBeds);
      }
      return room;
    }).toList();

    // Deactivate the lease
    final updatedLeases = state.leases.map((l) {
      if (l.id == leaseId) {
        return l.copyWith(
          isActive: false,
          endDate: DateTime.now(),
          moveOutNotes: notes,
        );
      }
      return l;
    }).toList();

    // Mark tenant as inactive
    final updatedTenants = state.tenants.map((t) {
      if (t.id == lease.tenantId) {
        return t.copyWith(status: TenantStatus.inactive);
      }
      return t;
    }).toList();

    state = state.copyWith(
      rooms: updatedRooms,
      leases: updatedLeases,
      tenants: updatedTenants,
    );
  }

  // ===========================================================================
  // SUB-METER ELECTRICITY ENGINE
  // ===========================================================================
  MeterReadingModel recordMeterReading({
    required String roomId,
    required double currentReading,
    required double ratePerUnit,
    String? photoUrl,
    String? notes,
  }) {
    final room = state.rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw ArgumentError('Room not found: $roomId'),
    );

    final previousReading = room.currentMeterReading;
    if (currentReading < previousReading) {
      throw ArgumentError(
        'Current reading ($currentReading) cannot be lower than previous reading ($previousReading)',
      );
    }

    final reading = MeterReadingModel(
      id: _uuid.v4(),
      roomId: roomId,
      readingDate: DateTime.now(),
      previousReading: previousReading,
      currentReading: currentReading,
      ratePerUnit: ratePerUnit,
      meterPhotoUrl: photoUrl,
      notes: notes,
    );

    // Update room's current meter reading
    final updatedRooms = state.rooms.map((r) {
      if (r.id == roomId) {
        return r.copyWith(
          currentMeterReading: currentReading,
          lastMeterReadingDate: DateTime.now(),
        );
      }
      return r;
    }).toList();

    state = state.copyWith(
      meterReadings: [...state.meterReadings, reading],
      rooms: updatedRooms,
    );

    return reading;
  }

  // ===========================================================================
  // INVOICING & BILLING ENGINE
  // ===========================================================================
  InvoiceModel generateInvoice({
    required String leaseId,
    required int month,
    required int year,
    double electricityCharges = 0.0,
    double maintenanceCharges = 0.0,
    double foodMessCharges = 0.0,
    double otherCharges = 0.0,
    double discount = 0.0,
    double lateFee = 0.0,
  }) {
    final lease = state.leases.firstWhere((l) => l.id == leaseId);
    final room = state.rooms.firstWhere((r) => r.id == lease.roomId);
    final invoiceNumber = 'INV-$year-${month.toString().padLeft(2, '0')}-${room.roomNumber}';

    final invoice = InvoiceModel(
      id: _uuid.v4(),
      leaseId: lease.id,
      tenantId: lease.tenantId,
      roomId: room.id,
      invoiceNumber: invoiceNumber,
      billingMonth: month,
      billingYear: year,
      issueDate: DateTime.now(),
      dueDate: DateTime(year, month, 5), // Default due by 5th
      baseRent: lease.agreedMonthlyRent,
      electricityCharges: electricityCharges,
      maintenanceCharges: maintenanceCharges,
      foodMessCharges: foodMessCharges,
      otherCharges: otherCharges,
      discountAmount: discount,
      lateFee: lateFee,
      amountPaid: 0.0,
      status: InvoiceStatus.pending,
      publicInvoiceToken: _uuid.v4(),
    );

    state = state.copyWith(invoices: [...state.invoices, invoice]);
    return invoice;
  }

  // ===========================================================================
  // PAYMENT RECORDING & LEDGER SETTLEMENT
  // ===========================================================================
  PaymentModel recordPayment({
    required String invoiceId,
    required double amount,
    PaymentMode mode = PaymentMode.upi,
    String? transactionRef,
    String? notes,
  }) {
    final invoice = state.invoices.firstWhere((i) => i.id == invoiceId);
    final receiptNumber = 'REC-${DateTime.now().year}-${(state.payments.length + 1).toString().padLeft(4, '0')}';

    final payment = PaymentModel(
      id: _uuid.v4(),
      invoiceId: invoiceId,
      amount: amount,
      paymentDate: DateTime.now(),
      paymentMode: mode,
      transactionRef: transactionRef,
      receiptNumber: receiptNumber,
      notes: notes,
    );

    final newTotalPaid = invoice.amountPaid + amount;
    final newStatus = newTotalPaid >= invoice.totalAmount
        ? InvoiceStatus.paid
        : (newTotalPaid > 0 ? InvoiceStatus.partiallyPaid : InvoiceStatus.pending);

    final updatedInvoices = state.invoices.map((inv) {
      if (inv.id == invoiceId) {
        return inv.copyWith(
          amountPaid: newTotalPaid,
          status: newStatus,
        );
      }
      return inv;
    }).toList();

    state = state.copyWith(
      payments: [...state.payments, payment],
      invoices: updatedInvoices,
    );

    return payment;
  }

  void updateInvoiceStatus(String invoiceId, InvoiceStatus newStatus) {
    final updatedInvoices = state.invoices.map((inv) {
      if (inv.id == invoiceId) {
        return inv.copyWith(status: newStatus);
      }
      return inv;
    }).toList();
    state = state.copyWith(invoices: updatedInvoices);
  }

  // ===========================================================================
  // DASHBOARD KPI AGGREGATION METRICS
  // ===========================================================================
  double getTotalExpectedRent(int month, int year) {
    return state.invoices
        .where((i) => i.billingMonth == month && i.billingYear == year)
        .fold(0.0, (sum, i) => sum + i.totalAmount);
  }

  double getTotalCollectedRent(int month, int year) {
    return state.invoices
        .where((i) => i.billingMonth == month && i.billingYear == year)
        .fold(0.0, (sum, i) => sum + i.amountPaid);
  }

  double getTotalPendingDues(int month, int year) {
    return state.invoices
        .where((i) => i.billingMonth == month && i.billingYear == year)
        .fold(0.0, (sum, i) => sum + i.balanceDue);
  }

  ({int totalBeds, int occupiedBeds, double occupancyRate}) getOccupancyStats() {
    int total = 0;
    int occupied = 0;
    for (final room in state.rooms) {
      total += room.beds.length;
      occupied += room.occupiedBedCount;
    }
    final rate = total > 0 ? (occupied / total) * 100 : 0.0;
    return (totalBeds: total, occupiedBeds: occupied, occupancyRate: rate);
  }
}

/// Global Riverpod Provider for RentKhataRepository
final rentKhataRepositoryProvider =
    StateNotifierProvider<RentKhataRepository, RentKhataState>((ref) {
  return RentKhataRepository();
});
