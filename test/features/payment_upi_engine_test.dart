import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:rent_manager/core/database/rent_khata_repository.dart';
import 'package:rent_manager/features/payment/domain/upi_uri_builder.dart';
import 'package:rent_manager/features/payment/presentation/payment_sheet.dart';
import 'package:rent_manager/features/payment/presentation/widgets/upi_qr_widget.dart';
import 'package:rent_manager/features/room/models/room_model.dart';

void main() {
  group('Step 8 Audit: UpiUriBuilder Domain Tests', () {
    test('Validates standard Indian UPI VPAs accurately', () {
      expect(UpiUriBuilder.isValidVpa('sharmaji@oksbi'), isTrue);
      expect(UpiUriBuilder.isValidVpa('9829012345@paytm'), isTrue);
      expect(UpiUriBuilder.isValidVpa('hostel.rent@icici'), isTrue);
      expect(UpiUriBuilder.isValidVpa('kota_pg-1@ybl'), isTrue);

      expect(UpiUriBuilder.isValidVpa(''), isFalse);
      expect(UpiUriBuilder.isValidVpa(null), isFalse);
      expect(UpiUriBuilder.isValidVpa('sharmaji'), isFalse);
      expect(UpiUriBuilder.isValidVpa('sharmaji@'), isFalse);
      expect(UpiUriBuilder.isValidVpa('@oksbi'), isFalse);
      expect(UpiUriBuilder.isValidVpa('invalid@@bank'), isFalse);
    });

    test('Constructs standardized NPCI UPI URI with exact parameters', () {
      final uriString = UpiUriBuilder.buildUriString(
        upiId: 'landlord@oksbi',
        payeeName: 'Ramesh Sharma',
        amount: 8140.0,
        transactionNote: 'Rent Room 101 Nov 2026',
      );

      expect(uriString, startsWith('upi://pay?'));
      expect(uriString, contains('pa=landlord@oksbi'));
      expect(uriString, contains('pn=Ramesh%20Sharma'));
      expect(uriString, contains('am=8140.00'));
      expect(uriString, contains('cu=INR'));
      expect(uriString, contains('tn=Rent%20Room%20101%20Nov%202026'));
    });

    test('Throws ArgumentError on invalid VPA or non-positive amount', () {
      expect(
        () => UpiUriBuilder.buildUriString(
          upiId: 'invalid-vpa',
          payeeName: 'Ramesh',
          amount: 5000.0,
        ),
        throwsArgumentError,
      );

      expect(
        () => UpiUriBuilder.buildUriString(
          upiId: 'valid@okaxis',
          payeeName: 'Ramesh',
          amount: 0.0,
        ),
        throwsArgumentError,
      );

      expect(
        () => UpiUriBuilder.buildUriString(
          upiId: 'valid@okaxis',
          payeeName: 'Ramesh',
          amount: -100.0,
        ),
        throwsArgumentError,
      );
    });

    test('Generates correct Web Bridge redirect URL', () {
      final bridgeUrl = UpiUriBuilder.generateWebBridgeUrl(
        invoiceToken: 'tok-abc-123',
      );
      expect(bridgeUrl, 'https://rentkhata.in/pay/tok-abc-123');
    });
  });

  group('Step 8 Audit: UPI QR & Payment Sheet Widget Tests', () {
    testWidgets('UpiQrWidget renders QR code and copyable VPA', (tester) async {
      const upiUri = 'upi://pay?pa=test@oksbi&pn=Hostel&am=7500.00&cu=INR&tn=Rent';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpiQrWidget(
              upiUri: upiUri,
              amount: 7500.0,
              payeeName: 'Krishna Residency',
              upiVpa: 'test@oksbi',
            ),
          ),
        ),
      );

      expect(find.text('Scan with any UPI App to Pay'), findsOneWidget);
      expect(find.text('₹7,500'), findsOneWidget);
      expect(find.text('test@oksbi'), findsOneWidget);
      expect(find.text('Payee: Krishna Residency'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.textContaining('BHIM  •  GPay  •  PhonePe'), findsOneWidget);
    });

    testWidgets('PaymentSheet renders scannable QR and action buttons', (tester) async {
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
      final inv = repo.generateInvoice(
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
          child: MaterialApp(
            home: Scaffold(
              body: PaymentSheet(
                invoice: inv,
                roomNumber: '101',
                tenantName: 'Aryan Mehta',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Instant UPI Payment'), findsOneWidget);
      expect(find.text('Room 101 • Aryan Mehta'), findsOneWidget);
      expect(find.text('₹8,500'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.textContaining('Open UPI App'), findsOneWidget);
      expect(find.text('Copy Direct UPI Payment Link'), findsOneWidget);
      expect(find.text('Received Cash instead? Record Payment Here'), findsOneWidget);
    });
  });
}
