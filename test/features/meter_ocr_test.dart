import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:rent_manager/core/database/rent_khata_repository.dart';
import 'package:rent_manager/features/meter/domain/meter_ocr_parser.dart';
import 'package:rent_manager/features/meter/services/meter_ocr_service.dart';
import 'package:rent_manager/features/room/models/room_model.dart';
import 'package:rent_manager/features/room/presentation/quick_meter_dialog.dart';

class MockMeterOcrService extends MeterOcrService {
  final double mockReading;
  final bool shouldSucceed;

  MockMeterOcrService({
    this.mockReading = 1080.0,
    this.shouldSucceed = true,
  });

  @override
  Future<MeterOcrScanResult> captureAndScan({
    required ImageSource source,
    double? previousReading,
  }) async {
    if (!shouldSucceed) {
      return MeterOcrScanResult.failure('Scan failed');
    }
    return MeterOcrScanResult(
      reading: mockReading,
      rawText: '$mockReading kWh',
      imagePath: 'mock_meter_scan.jpg',
      isSuccess: true,
      confidence: 0.95,
    );
  }
}

void main() {
  group('Step 6b: Smart AI Meter OCR Parser Unit Tests', () {
    test('Correctly extracts reading with kWh unit from Genus/Secure style OCR output', () {
      const sampleOcrText = 'GENUS POWER INFRASTRUCTURES LTD\n'
          '240V 50Hz Class 1.0\n'
          '01080.5 kWh\n'
          'DATE: 2026/04/30';

      final result = MeterOcrParser.parse(sampleOcrText, previousReading: 1000.0);

      expect(result.hasReading, isTrue);
      expect(result.reading, 1080.5);
      expect(result.confidence, greaterThanOrEqualTo(0.9));
      expect(result.isHighConfidence, isTrue);
    });

    test('Correctly extracts reading when unit is uppercase KWH', () {
      const sampleOcrText = 'SECURE METERS\n'
          'TOTAL CUMULATIVE: 00450 KWH\n'
          'MTR-102';

      final result = MeterOcrParser.parse(sampleOcrText);

      expect(result.hasReading, isTrue);
      expect(result.reading, 450.0);
    });

    test('Filters out voltage, frequency, and date numbers to find pure reading', () {
      const sampleOcrText = 'HPL ELECTRIC\n'
          '230 V\n'
          '50 Hz\n'
          '01/04/2026\n'
          '1240 Units';

      final result = MeterOcrParser.parse(sampleOcrText);

      expect(result.hasReading, isTrue);
      expect(result.reading, 1240.0);
    });

    test('Heuristic selects plausible number >= previous reading when multiple numbers present', () {
      const sampleOcrText = 'SUB METER 101\n'
          'VOLTS: 240\n'
          'PREV: 1000\n'
          'CURR: 1095\n'
          'PF: 0.98';

      final result = MeterOcrParser.parse(sampleOcrText, previousReading: 1000.0);

      expect(result.hasReading, isTrue);
      expect(result.reading, 1095.0);
    });

    test('Handles 7-segment character misrecognitions like O for 0', () {
      const corruptedText = '01O80 kWh';
      final sanitized = MeterOcrParser.sanitizeOcrText(corruptedText);
      expect(sanitized, contains('01080'));

      final result = MeterOcrParser.parse(corruptedText);
      expect(result.reading, 1080.0);
    });

    test('Returns failure result gracefully when no plausible digits are found', () {
      const emptyOcrText = 'RANDOM WALL POSTER NO NUMBERS';
      final result = MeterOcrParser.parse(emptyOcrText);

      expect(result.hasReading, isFalse);
      expect(result.reading, isNull);
    });
  });

  group('Step 6b: QuickMeterDialog AI Scanner Widget Tests', () {
    testWidgets('QuickMeterDialog displays AI Smart Meter Scan action banner', (tester) async {
      final repo = RentKhataRepository();
      final property = repo.addProperty(
        name: 'Krishna Residency',
        address: 'Kunadi',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324008',
      );
      final room = repo.addRoom(
        propertyId: property.id,
        roomNumber: '101',
        floorNumber: 1,
        sharingType: RoomSharingType.single,
        baseRentPerBed: 7500.0,
        initialMeterReading: 1000.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: QuickMeterDialog(
                room: room,
                defaultRate: 10.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AI banner and scan buttons
      expect(find.text('AI Smart Meter Scan'), findsOneWidget);
      expect(find.text('Camera Scan'), findsOneWidget);
      expect(find.text('Upload Photo'), findsOneWidget);
    });

    testWidgets('Tapping AI Scan updates reading, attaches photo proof and recalculates bill', (tester) async {
      final repo = RentKhataRepository();
      final property = repo.addProperty(
        name: 'Krishna Residency',
        address: 'Kunadi',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324008',
      );
      final room = repo.addRoom(
        propertyId: property.id,
        roomNumber: '101',
        floorNumber: 1,
        sharingType: RoomSharingType.single,
        baseRentPerBed: 7500.0,
        initialMeterReading: 1000.0,
      );

      final mockService = MockMeterOcrService(mockReading: 1080.0);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: QuickMeterDialog(
                room: room,
                defaultRate: 10.0,
                ocrService: mockService,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial reading is 1000
      expect(find.text('1000'), findsOneWidget); // in TextField
      expect(find.text('Last Dial: 1000 Units'), findsOneWidget);

      // Tap Camera Scan directly in AI banner
      final scanButton = find.widgetWithText(OutlinedButton, 'Camera Scan');
      expect(scanButton, findsOneWidget);
      await tester.tap(scanButton);
      await tester.pumpAndSettle();

      // Verify reading updated to 1080
      expect(find.text('1080'), findsOneWidget);

      // Verify AI Detection confirmation message appears
      expect(find.textContaining('AI Detected: 1080 Units'), findsOneWidget);

      // Verify math calculation: 1080 - 1000 = 80 units @ ₹10 = ₹800
      expect(find.text('80 Units'), findsOneWidget);
      expect(find.text('₹800'), findsOneWidget);

      // Scroll and save the reading
      await tester.ensureVisible(find.text('Save & Update Reading'));
      await tester.tap(find.text('Save & Update Reading'));
      await tester.pumpAndSettle();

      // Verify reading recorded in repo state
      expect(repo.state.meterReadings.length, 1);
      expect(repo.state.meterReadings.first.currentReading, 1080.0);
      expect(repo.state.meterReadings.first.unitsConsumed, 80.0);
    });
  });
}
