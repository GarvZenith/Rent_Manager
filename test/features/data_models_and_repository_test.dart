import 'package:flutter_test/flutter_test.dart';
import 'package:rent_manager/features/property/models/property_model.dart';
import 'package:rent_manager/features/room/models/room_model.dart';
import 'package:rent_manager/features/meter/models/meter_reading_model.dart';
import 'package:rent_manager/features/invoice/models/invoice_model.dart';
import 'package:rent_manager/features/payment/models/payment_model.dart';
import 'package:rent_manager/core/database/rent_khata_repository.dart';

void main() {
  group('Step 3 Audit: Domain Model Math & Validation Tests', () {
    test('PropertyModel serialization round-trip', () {
      final property = PropertyModel(
        id: 'prop-1',
        name: 'Krishna Residency',
        address: 'Talwandi Circle',
        city: 'Kota',
        state: 'Rajasthan',
        pincode: '324005',
        upiVpa: 'sharmaji@oksbi',
        createdAt: DateTime.now(),
      );

      final json = property.toJson();
      final fromJson = PropertyModel.fromJson(json);

      expect(fromJson.name, 'Krishna Residency');
      expect(fromJson.city, 'Kota');
      expect(fromJson.upiVpa, 'sharmaji@oksbi');
    });

    test('MeterReadingModel correctly calculates units and cost', () {
      final reading = MeterReadingModel(
        id: 'meter-1',
        roomId: 'room-1',
        readingDate: DateTime.now(),
        previousReading: 1146.0,
        currentReading: 1210.0,
        ratePerUnit: 10.0,
      );

      expect(reading.unitsConsumed, 64.0);
      expect(reading.totalAmount, 640.0);
      expect(reading.isValid, isTrue);
    });

    test('InvoiceModel accurately computes itemized total and balance due', () {
      final invoice = InvoiceModel(
        id: 'inv-1',
        leaseId: 'lease-1',
        tenantId: 'tenant-1',
        roomId: 'room-1',
        invoiceNumber: 'INV-2026-03-101',
        billingMonth: 3,
        billingYear: 2026,
        issueDate: DateTime(2026, 3, 1),
        dueDate: DateTime(2026, 3, 5),
        baseRent: 7500.0,
        electricityCharges: 640.0,
        maintenanceCharges: 300.0,
        foodMessCharges: 1500.0,
        discountAmount: 200.0,
        amountPaid: 5000.0,
      );

      // (7500 + 640 + 300 + 1500) - 200 = 9740
      expect(invoice.totalAmount, 9740.0);
      // 9740 - 5000 = 4740
      expect(invoice.balanceDue, 4740.0);
      expect(invoice.isFullyPaid, isFalse);
    });
  });

  group('Step 3 Audit: RentKhataRepository Full Lifecycle Integration', () {
    late RentKhataRepository repo;

    setUp(() {
      repo = RentKhataRepository();
    });

    test('Complete Lifecycle: Property -> Room -> Bed -> Tenant -> Meter -> Invoice -> Payment', () {
      // 1. Add Property
      final property = repo.addProperty(
        name: 'Krishna Residency',
        address: 'Landmark City',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324005',
        defaultElectricityRate: 10.0,
        upiVpa: 'sharmaji@oksbi',
        upiAccountName: 'Ramesh Sharma',
      );
      expect(repo.state.properties.length, 1);

      // 2. Add Room (Double Sharing: 2 beds generated automatically)
      final room = repo.addRoom(
        propertyId: property.id,
        roomNumber: '101',
        floorNumber: 1,
        sharingType: RoomSharingType.doubleSharing,
        baseRentPerBed: 7500.0,
        subMeterNumber: 'MTR-101',
        initialMeterReading: 1000.0,
      );
      expect(room.beds.length, 2);
      expect(room.beds[0].bedLabel, 'Bed A');
      expect(room.beds[1].bedLabel, 'Bed B');
      expect(room.hasVacantBed, isTrue);

      // 3. Onboard Tenant into Bed A
      final bedAId = room.beds[0].id;
      final onboarding = repo.onboardTenant(
        roomId: room.id,
        bedId: bedAId,
        fullName: 'Rahul Sharma',
        phone: '9876543210',
        workplaceOrCollege: 'Allen Kota',
        agreedRent: 7500.0,
        securityDeposit: 15000.0,
      );

      // Verify Bed A is occupied, Bed B is still vacant
      final updatedRoom = repo.state.rooms.firstWhere((r) => r.id == room.id);
      expect(updatedRoom.beds.firstWhere((b) => b.id == bedAId).isOccupied, isTrue);
      expect(updatedRoom.beds[1].isOccupied, isFalse);
      expect(updatedRoom.occupiedBedCount, 1);

      // 4. Record Sub-Meter Reading (1000 -> 1080 units = 80 units @ ₹10 = ₹800)
      final reading = repo.recordMeterReading(
        roomId: room.id,
        currentReading: 1080.0,
        ratePerUnit: 10.0,
      );
      expect(reading.unitsConsumed, 80.0);
      expect(reading.totalAmount, 800.0);

      // Verify room's current reading updated
      final roomAfterMeter = repo.state.rooms.firstWhere((r) => r.id == room.id);
      expect(roomAfterMeter.currentMeterReading, 1080.0);

      // 5. Generate Invoice (Rent ₹7500 + Half Electricity ₹400 = ₹7900)
      final invoice = repo.generateInvoice(
        leaseId: onboarding.lease.id,
        month: 3,
        year: 2026,
        electricityCharges: 400.0, // Shared half electricity
      );
      expect(invoice.totalAmount, 7900.0);
      expect(invoice.balanceDue, 7900.0);
      expect(invoice.status, InvoiceStatus.pending);

      // 6. Record Partial Payment (₹4,000 paid via UPI)
      repo.recordPayment(
        invoiceId: invoice.id,
        amount: 4000.0,
        mode: PaymentMode.upi,
        transactionRef: 'UPI-492019482',
      );
      final invoiceAfterPartial = repo.state.invoices.firstWhere((i) => i.id == invoice.id);
      expect(invoiceAfterPartial.amountPaid, 4000.0);
      expect(invoiceAfterPartial.balanceDue, 3900.0);
      expect(invoiceAfterPartial.status, InvoiceStatus.partiallyPaid);

      // 7. Settle Remaining Balance (₹3,900 paid via Cash)
      repo.recordPayment(
        invoiceId: invoice.id,
        amount: 3900.0,
        mode: PaymentMode.cash,
      );
      final invoiceSettled = repo.state.invoices.firstWhere((i) => i.id == invoice.id);
      expect(invoiceSettled.amountPaid, 7900.0);
      expect(invoiceSettled.balanceDue, 0.0);
      expect(invoiceSettled.status, InvoiceStatus.paid);
      expect(invoiceSettled.isFullyPaid, isTrue);

      // 8. Check Dashboard KPIs
      expect(repo.getTotalExpectedRent(3, 2026), 7900.0);
      expect(repo.getTotalCollectedRent(3, 2026), 7900.0);
      expect(repo.getTotalPendingDues(3, 2026), 0.0);

      final occ = repo.getOccupancyStats();
      expect(occ.totalBeds, 2);
      expect(occ.occupiedBeds, 1);
      expect(occ.occupancyRate, 50.0); // 1 out of 2 beds occupied
    });
  });
}
