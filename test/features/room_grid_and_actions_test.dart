import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rent_manager/main.dart';
import 'package:rent_manager/features/room/models/room_model.dart';
import 'package:rent_manager/features/room/models/bed_model.dart';
import 'package:rent_manager/features/invoice/models/invoice_model.dart';
import 'package:rent_manager/features/room/presentation/widgets/room_card.dart';
import 'package:rent_manager/features/room/presentation/quick_meter_dialog.dart';

void main() {
  group('Step 4 Audit: RoomCard Widget & Visual Badges Tests', () {
    testWidgets('RoomCard displays correct Room #, Rent and Vacant status', (tester) async {
      final room = RoomModel(
        id: 'r-1',
        propertyId: 'p-1',
        roomNumber: '101',
        sharingType: RoomSharingType.single,
        baseRentPerBed: 7500.0,
        currentMeterReading: 1000.0,
        beds: const [
          BedModel(id: 'b-1', roomId: 'r-1', bedLabel: 'Single', isOccupied: false),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomCard(room: room),
          ),
        ),
      );

      expect(find.text('Room 101'), findsOneWidget);
      expect(find.text('₹7,500'), findsOneWidget);
      expect(find.text('Vacant (खाली)'), findsOneWidget);
    });

    testWidgets('RoomCard displays Paid status when invoice is paid', (tester) async {
      final room = RoomModel(
        id: 'r-1',
        propertyId: 'p-1',
        roomNumber: '101',
        sharingType: RoomSharingType.single,
        baseRentPerBed: 7500.0,
        beds: const [
          BedModel(id: 'b-1', roomId: 'r-1', bedLabel: 'Single', isOccupied: true),
        ],
      );

      final invoice = InvoiceModel(
        id: 'inv-1',
        leaseId: 'l-1',
        tenantId: 't-1',
        roomId: 'r-1',
        invoiceNumber: 'INV-101',
        billingMonth: 3,
        billingYear: 2026,
        issueDate: DateTime.now(),
        dueDate: DateTime.now(),
        baseRent: 7500.0,
        amountPaid: 7500.0,
        status: InvoiceStatus.paid,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomCard(room: room, latestInvoice: invoice),
          ),
        ),
      );

      expect(find.text('Paid (जमा)'), findsOneWidget);
    });
  });

  group('Step 4 Audit: QuickMeterDialog Calculation Test', () {
    testWidgets('QuickMeterDialog calculates delta units and total cost', (tester) async {
      final room = RoomModel(
        id: 'r-1',
        propertyId: 'p-1',
        roomNumber: '101',
        baseRentPerBed: 7500.0,
        currentMeterReading: 1000.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: QuickMeterDialog(room: room, defaultRate: 10.0),
            ),
          ),
        ),
      );

      // Verify previous reading is shown
      expect(find.textContaining('1000 Units'), findsOneWidget);

      // Enter new reading 1080
      final textField = find.byType(TextField);
      await tester.enterText(textField, '1080');
      await tester.pump();

      // Verify math calculation: 80 units @ ₹10 = ₹800
      expect(find.text('80 Units'), findsOneWidget);
      expect(find.text('₹800'), findsOneWidget);
    });
  });

  group('Step 4 Audit: Dashboard Integration & Pre-load Sample PG Data Test', () {
    testWidgets('Pre-load Sample PG Data button loads 4 rooms and updates KPIs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RentManagerApp(),
        ),
      );

      // Initially empty
      expect(find.text('No rooms added yet (अभी कोई कमरा नहीं है)'), findsOneWidget);

      // Tap Pre-load Sample PG Data
      final preloadBtn = find.text('⚡ Pre-load Kota PG Demo (Live Test)');
      expect(preloadBtn, findsOneWidget);
      await tester.tap(preloadBtn);
      await tester.pumpAndSettle();

      // Now 4 rooms are loaded
      expect(find.text('Room 101'), findsOneWidget);
      expect(find.text('Room 102'), findsOneWidget);
      expect(find.text('Room 103'), findsOneWidget);
      expect(find.text('Room 104'), findsOneWidget);

      // Verify Badges are visible on screen
      expect(find.text('Paid (जमा)'), findsOneWidget); // Room 101
      expect(find.text('Overdue (बाकी)'), findsOneWidget); // Room 102
      expect(find.text('Due (देना है)'), findsOneWidget); // Room 103
      expect(find.text('Vacant (खाली)'), findsOneWidget); // Room 104

      // Verify Top Bar updated with Property Name
      expect(find.text('Krishna Residency (Kota)'), findsOneWidget);
    });
  });
}
