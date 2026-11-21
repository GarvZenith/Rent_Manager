import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rent_manager/core/database/rent_khata_repository.dart';
import 'package:rent_manager/features/invoice/domain/invoice_generator.dart';
import 'package:rent_manager/features/invoice/models/invoice_model.dart';
import 'package:rent_manager/features/invoice/presentation/invoice_detail_screen.dart';
import 'package:rent_manager/features/invoice/presentation/invoice_list_screen.dart';
import 'package:rent_manager/features/room/models/room_model.dart';
import 'package:rent_manager/features/tenant/models/lease_model.dart';

void main() {
  group('Step 7 Audit: InvoiceGenerator Domain Math Tests', () {
    test('Calculates days in month correctly including leap years', () {
      expect(InvoiceGenerator.getDaysInMonth(1, 2026), 31);
      expect(InvoiceGenerator.getDaysInMonth(4, 2026), 30);
      expect(InvoiceGenerator.getDaysInMonth(2, 2025), 28); // Non-leap year
      expect(InvoiceGenerator.getDaysInMonth(2, 2024), 29); // Leap year 2024
      expect(InvoiceGenerator.getDaysInMonth(2, 2000), 29); // Century leap year
      expect(InvoiceGenerator.getDaysInMonth(2, 1900), 28); // Century non-leap year

      expect(() => InvoiceGenerator.getDaysInMonth(13, 2026), throwsArgumentError);
      expect(() => InvoiceGenerator.getDaysInMonth(0, 2026), throwsArgumentError);
    });

    test('Full month rent is charged when tenant moves in on or before the 1st', () {
      final rent = InvoiceGenerator.calculateProRataRent(
        agreedMonthlyRent: 8000.0,
        startDate: DateTime(2026, 11, 1),
        billingMonth: 11,
        billingYear: 2026,
      );
      expect(rent, 8000.0);

      final rentPast = InvoiceGenerator.calculateProRataRent(
        agreedMonthlyRent: 7500.0,
        startDate: DateTime(2026, 5, 10),
        billingMonth: 11,
        billingYear: 2026,
      );
      expect(rentPast, 7500.0);
    });

    test('Pro-rata rent calculated accurately for mid-month joining', () {
      // November 2026 has 30 days. Joined on Nov 16 -> 15 active days (16 to 30)
      // (8000 / 30) * 15 = 4000.0
      final rentNov = InvoiceGenerator.calculateProRataRent(
        agreedMonthlyRent: 8000.0,
        startDate: DateTime(2026, 11, 16),
        billingMonth: 11,
        billingYear: 2026,
      );
      expect(rentNov, 4000.0);

      // October has 31 days. Joined on Oct 11 -> 21 active days
      // (9300 / 31) * 21 = 300 * 21 = 6300.0
      final rentOct = InvoiceGenerator.calculateProRataRent(
        agreedMonthlyRent: 9300.0,
        startDate: DateTime(2026, 10, 11),
        billingMonth: 10,
        billingYear: 2026,
      );
      expect(rentOct, 6300.0);
    });

    test('Leap year February pro-rata handles 29 vs 28 days', () {
      // Feb 2024 (29 days). Joined on Feb 15 -> 15 active days
      // (8700 / 29) * 15 = 300 * 15 = 4500.0
      final rentLeap = InvoiceGenerator.calculateProRataRent(
        agreedMonthlyRent: 8700.0,
        startDate: DateTime(2024, 2, 15),
        billingMonth: 2,
        billingYear: 2024,
      );
      expect(rentLeap, 4500.0);

      // Feb 2025 (28 days). Joined on Feb 15 -> 14 active days
      // (8400 / 28) * 14 = 300 * 14 = 4200.0
      final rentNonLeap = InvoiceGenerator.calculateProRataRent(
        agreedMonthlyRent: 8400.0,
        startDate: DateTime(2025, 2, 15),
        billingMonth: 2,
        billingYear: 2025,
      );
      expect(rentNonLeap, 4200.0);
    });

    test('Future lease returns 0 rent for current month', () {
      final rentFuture = InvoiceGenerator.calculateProRataRent(
        agreedMonthlyRent: 8000.0,
        startDate: DateTime(2026, 12, 1),
        billingMonth: 11,
        billingYear: 2026,
      );
      expect(rentFuture, 0.0);
    });

    test('Accumulates past unpaid arrears correctly while ignoring settled/cancelled bills', () {
      final invoices = [
        InvoiceModel(
          id: 'inv-1',
          leaseId: 'l1',
          tenantId: 't1',
          roomId: 'r1',
          invoiceNumber: 'INV-1',
          billingMonth: 9,
          billingYear: 2026,
          issueDate: DateTime(2026, 9, 1),
          dueDate: DateTime(2026, 9, 5),
          baseRent: 8000.0,
          amountPaid: 8000.0,
          status: InvoiceStatus.paid,
        ),
        InvoiceModel(
          id: 'inv-2',
          leaseId: 'l1',
          tenantId: 't1',
          roomId: 'r1',
          invoiceNumber: 'INV-2',
          billingMonth: 10,
          billingYear: 2026,
          issueDate: DateTime(2026, 10, 1),
          dueDate: DateTime(2026, 10, 5),
          baseRent: 8000.0,
          amountPaid: 5000.0, // 3000 pending
          status: InvoiceStatus.partiallyPaid,
        ),
      ];

      final arrears = InvoiceGenerator.calculateArrears(
        previousInvoices: invoices,
        currentMonth: 11,
        currentYear: 2026,
      );
      expect(arrears, 3000.0);
    });

    test('Late fee calculation accumulates per day and respects cap', () {
      final dueDate = DateTime(2026, 11, 5);

      // Not late
      expect(
        InvoiceGenerator.calculateLateFee(
          dueDate: dueDate,
          currentDate: DateTime(2026, 11, 4),
        ),
        0.0,
      );

      // 4 days late: 4 * 50 = 200
      expect(
        InvoiceGenerator.calculateLateFee(
          dueDate: dueDate,
          currentDate: DateTime(2026, 11, 9),
          perDayRate: 50.0,
          maxLateFee: 500.0,
        ),
        200.0,
      );

      // 20 days late: 20 * 50 = 1000, capped at 500
      expect(
        InvoiceGenerator.calculateLateFee(
          dueDate: dueDate,
          currentDate: DateTime(2026, 11, 25),
          perDayRate: 50.0,
          maxLateFee: 500.0,
        ),
        500.0,
      );
    });

    test('Batch generation is idempotent and splits room electricity among roommates', () {
      final lease1 = LeaseModel(
        id: 'lease-1',
        roomId: 'room-101',
        bedId: 'bed-1',
        tenantId: 'tenant-1',
        agreedMonthlyRent: 7000.0,
        securityDepositAmount: 14000.0,
        startDate: DateTime(2026, 1, 1),
      );
      final lease2 = LeaseModel(
        id: 'lease-2',
        roomId: 'room-101',
        bedId: 'bed-2',
        tenantId: 'tenant-2',
        agreedMonthlyRent: 7000.0,
        securityDepositAmount: 14000.0,
        startDate: DateTime(2026, 1, 1),
      );
      final room101 = RoomModel(
        id: 'room-101',
        propertyId: 'prop-1',
        roomNumber: '101',
        floorNumber: 1,
        sharingType: RoomSharingType.doubleSharing,
        baseRentPerBed: 7000.0,
      );

      // Total room electricity is ₹800. Split between 2 roommates should be ₹400 each.
      final batch = InvoiceGenerator.generateBatchInvoices(
        activeLeases: [lease1, lease2],
        rooms: [room101],
        existingInvoices: [],
        billingMonth: 11,
        billingYear: 2026,
        roomElectricityCharges: {'room-101': 800.0},
      );

      expect(batch.length, 2);
      expect(batch[0].electricityCharges, 400.0);
      expect(batch[1].electricityCharges, 400.0);
      expect(batch[0].totalAmount, 7400.0);

      // Running batch generation again with existing invoices returns 0 new invoices
      final secondRun = InvoiceGenerator.generateBatchInvoices(
        activeLeases: [lease1, lease2],
        rooms: [room101],
        existingInvoices: batch,
        billingMonth: 11,
        billingYear: 2026,
      );
      expect(secondRun.length, 0);
    });
  });

  group('Step 7 Audit: Invoicing UI Widget Tests', () {
    testWidgets('InvoiceListScreen renders bills and allows searching', (tester) async {
      final repo = RentKhataRepository();
      final prop = repo.addProperty(
        name: 'Kota PG',
        address: 'Kunhari',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324008',
      );
      final r1 = repo.addRoom(
        propertyId: prop.id,
        roomNumber: '101',
        floorNumber: 1,
        sharingType: RoomSharingType.single,
        baseRentPerBed: 8000.0,
      );
      final ob1 = repo.onboardTenant(
        roomId: r1.id,
        bedId: r1.beds[0].id,
        fullName: 'Aryan Mehta',
        phone: '9829011111',
        agreedRent: 8000.0,
        securityDeposit: 16000.0,
      );
      repo.generateInvoice(
        leaseId: ob1.lease.id,
        month: 11,
        year: 2026,
        electricityCharges: 500.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: const MaterialApp(
            home: InvoiceListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rent Bills & Invoices'), findsOneWidget);
      expect(find.text('Aryan Mehta'), findsOneWidget);
      expect(find.text('Room 101'), findsOneWidget);
      expect(find.textContaining('Due: ₹8,500'), findsOneWidget);

      // Test Search
      await tester.enterText(find.byType(TextField), 'Aryan');
      await tester.pumpAndSettle();
      expect(find.text('Aryan Mehta'), findsOneWidget);

      // Search non-existing
      await tester.enterText(find.byType(TextField), 'NonExistent');
      await tester.pumpAndSettle();
      expect(find.text('Aryan Mehta'), findsNothing);
      expect(find.text('No invoices found matching your criteria.'), findsOneWidget);
    });

    testWidgets('InvoiceDetailScreen displays full itemization and actions', (tester) async {
      final repo = RentKhataRepository();
      final prop = repo.addProperty(
        name: 'Kota PG',
        address: 'Kunhari',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324008',
      );
      final r1 = repo.addRoom(
        propertyId: prop.id,
        roomNumber: '102',
        floorNumber: 1,
        sharingType: RoomSharingType.single,
        baseRentPerBed: 7500.0,
      );
      final ob1 = repo.onboardTenant(
        roomId: r1.id,
        bedId: r1.beds[0].id,
        fullName: 'Deepak Joshi',
        phone: '9829022222',
        agreedRent: 7500.0,
        securityDeposit: 15000.0,
      );
      final inv = repo.generateInvoice(
        leaseId: ob1.lease.id,
        month: 11,
        year: 2026,
        electricityCharges: 620.0,
        maintenanceCharges: 300.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            home: InvoiceDetailScreen(invoiceId: inv.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(inv.invoiceNumber), findsOneWidget);
      expect(find.text('Deepak Joshi'), findsOneWidget);
      expect(find.text('Base Rent (कमरा किराया)'), findsOneWidget);
      expect(find.text('Electricity / Sub-Meter (बिजली बिल)'), findsOneWidget);
      expect(find.text('Maintenance Charges (रखरखाव)'), findsOneWidget);
      expect(find.text('Record Payment (रुपये जमा करें)'), findsOneWidget);
      expect(find.text('Copy WhatsApp Rent Bill Text'), findsOneWidget);
    });
  });
}
