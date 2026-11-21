import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rent_manager/core/database/rent_khata_repository.dart';
import 'package:rent_manager/features/meter/domain/electricity_calculator.dart';
import 'package:rent_manager/features/meter/presentation/meter_history_dialog.dart';

void main() {
  group('Step 6 Audit: ElectricityCalculator Domain Math Tests', () {
    test('Calculates units consumed and total amount accurately', () {
      final result = ElectricityCalculator.calculate(
        previousReading: 1146.0,
        currentReading: 1210.0,
        ratePerUnit: 10.0,
      );

      expect(result.unitsConsumed, 64.0);
      expect(result.totalRoomAmount, 640.0);
      expect(result.perTenantAmount, 640.0);
      expect(result.isSurgeWarning, isFalse);
    });

    test('Splits bill equally among multiple roommates in shared room', () {
      final result = ElectricityCalculator.calculate(
        previousReading: 1000.0,
        currentReading: 1100.0,
        ratePerUnit: 10.0,
        activeTenantsCount: 2, // Double sharing
      );

      expect(result.unitsConsumed, 100.0);
      expect(result.totalRoomAmount, 1000.0);
      expect(result.perTenantAmount, 500.0); // 1000 / 2 = 500
    });

    test('Throws ArgumentError if current reading is less than previous', () {
      expect(
        () => ElectricityCalculator.calculate(
          previousReading: 1200.0,
          currentReading: 1150.0,
          ratePerUnit: 10.0,
        ),
        throwsArgumentError,
      );
    });

    test('Detects unusual consumption surge (>200% jump)', () {
      final result = ElectricityCalculator.calculate(
        previousReading: 1000.0,
        currentReading: 1250.0, // 250 units consumed
        ratePerUnit: 10.0,
        lastCycleUnitsConsumed: 80.0, // Last month was only 80 units
      );

      expect(result.unitsConsumed, 250.0);
      expect(result.isSurgeWarning, isTrue);
      expect(result.surgePercentage, greaterThanOrEqualTo(200.0));
    });

    test('Generates complete WhatsApp mathematical proof string', () {
      final result = ElectricityCalculator.calculate(
        previousReading: 1146.0,
        currentReading: 1210.0,
        ratePerUnit: 10.0,
        activeTenantsCount: 2,
      );

      final waText = result.toWhatsAppMathString(roomNumber: '101');
      expect(waText, contains('Room 101'));
      expect(waText, contains('1146 Units'));
      expect(waText, contains('1210 Units'));
      expect(waText, contains('64 Units'));
      expect(waText, contains('₹640'));
      expect(waText, contains('₹320 per student'));
    });
  });

  group('Step 6 Audit: MeterHistoryDialog Widget Tests', () {
    testWidgets('MeterHistoryDialog renders reading history and copy proof button', (tester) async {
      final repo = RentKhataRepository();
      final property = repo.addProperty(
        name: 'Test PG',
        address: 'Main St',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324005',
      );

      final room = repo.addRoom(
        propertyId: property.id,
        roomNumber: '101',
        baseRentPerBed: 7500.0,
        subMeterNumber: 'MTR-101',
        initialMeterReading: 1000.0,
      );

      // Record 2 historical readings
      repo.recordMeterReading(roomId: room.id, currentReading: 1080.0, ratePerUnit: 10.0);
      repo.recordMeterReading(roomId: room.id, currentReading: 1160.0, ratePerUnit: 10.0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MeterHistoryDialog(room: room, ratePerUnit: 10.0),
            ),
          ),
        ),
      );

      expect(find.text('Room 101 - Meter History'), findsOneWidget);
      expect(find.text('Sub-Meter: MTR-101 • ₹10.0/unit'), findsOneWidget);

      // Verify that 2 historical entries are displayed
      expect(find.text('Copy WhatsApp Math Proof'), findsNWidgets(2));
    });
  });
}
