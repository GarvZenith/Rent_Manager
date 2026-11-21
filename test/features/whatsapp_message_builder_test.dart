import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rent_manager/core/database/rent_khata_repository.dart';
import 'package:rent_manager/features/invoice/models/invoice_model.dart';
import 'package:rent_manager/features/meter/models/meter_reading_model.dart';
import 'package:rent_manager/features/payment/models/payment_model.dart';
import 'package:rent_manager/features/room/models/room_model.dart';
import 'package:rent_manager/features/tenant/models/tenant_model.dart';
import 'package:rent_manager/features/whatsapp/domain/whatsapp_message_builder.dart';
import 'package:rent_manager/features/whatsapp/presentation/send_reminder_sheet.dart';

void main() {
  group('Step 9 Audit: WhatsApp Message Builder Domain & URL Encoding Tests', () {
    test('Normalizes Indian phone numbers accurately to E.164 standard', () {
      expect(
        WhatsAppMessageBuilder.normalizeIndianPhoneNumber('9829012345'),
        '919829012345',
      );
      expect(
        WhatsAppMessageBuilder.normalizeIndianPhoneNumber('+91 98290-12345'),
        '919829012345',
      );
      expect(
        WhatsAppMessageBuilder.normalizeIndianPhoneNumber('09829012345'),
        '919829012345',
      );
      expect(
        WhatsAppMessageBuilder.normalizeIndianPhoneNumber('919829012345'),
        '919829012345',
      );
    });

    test('Builds valid UTF-8 percent-encoded https://wa.me URI', () {
      final uri = WhatsAppMessageBuilder.buildWhatsAppUri(
        phoneNumber: '9829012345',
        message: 'Namaste Rahul ji! Rent ₹8,500 due 🏠',
      );

      final uriString = uri.toString();
      expect(uriString, startsWith('https://wa.me/919829012345?text='));
      expect(uriString, contains('Namaste%20Rahul%20ji'));
      // Verifies Rupee sign (₹) and emoji are safely encoded
      expect(uriString, contains('%E2%82%B98%2C500'));
    });

    final testTenant = TenantModel(
      id: 't-1',
      fullName: 'Rahul Sharma',
      phone: '9829012345',
      workplaceOrCollege: 'Allen Institute Kota',
      status: TenantStatus.active,
      createdAt: DateTime(2026, 1, 1),
    );

    final testRoom = RoomModel(
      id: 'r-1',
      propertyId: 'p-1',
      roomNumber: '101',
      floorNumber: 1,
      sharingType: RoomSharingType.doubleSharing,
      baseRentPerBed: 7500.0,
    );

    final testInvoice = InvoiceModel(
      id: 'inv-1',
      leaseId: 'l-1',
      tenantId: 't-1',
      roomId: 'r-1',
      invoiceNumber: 'INV-2026-11-101',
      billingMonth: 11,
      billingYear: 2026,
      issueDate: DateTime(2026, 11, 1),
      dueDate: DateTime(2026, 11, 5),
      baseRent: 7500.0,
      electricityCharges: 640.0,
      maintenanceCharges: 200.0,
      lateFee: 0.0,
      discountAmount: 0.0,
      amountPaid: 0.0,
      status: InvoiceStatus.pending,
    );

    final testMeterReading = MeterReadingModel(
      id: 'mr-1',
      roomId: 'r-1',
      readingDate: DateTime(2026, 11, 1),
      previousReading: 1000.0,
      currentReading: 1080.0,
      ratePerUnit: 10.0,
    );

    test('Formats Monthly Rent Bill template with sub-meter math and UPI link (Hinglish)', () {
      final text = WhatsAppMessageBuilder.buildMonthlyRentBill(
        tenant: testTenant,
        room: testRoom,
        invoice: testInvoice,
        meterReading: testMeterReading,
        activeRoommatesCount: 2,
        propertyName: 'Krishna Residency',
        upiVpa: 'landlord@oksbi',
        upiPayeeName: 'Krishna Residency',
        language: WhatsAppLanguage.hinglish,
      );

      expect(text, contains('Krishna Residency - Rent Bill'));
      expect(text, contains('Namaste *Rahul Sharma* ji!'));
      expect(text, contains('Room *101*'));
      expect(text, contains('Base Rent:* ₹7,500'));
      expect(text, contains('Electricity:* ₹640'));
      expect(text, contains('1000 ➔ 1080 = 80 Units @ ₹10/unit'));
      expect(text, contains('Split among 2 roommates'));
      expect(text, contains('Maintenance:* ₹200'));
      expect(text, contains('Total Due Amount:* *₹8,340*'));
      expect(text, contains('upi://pay?pa=landlord@oksbi'));
      expect(text, contains('INV-2026-11-101'));
    });

    test('Formats Monthly Rent Bill template (English)', () {
      final text = WhatsAppMessageBuilder.buildMonthlyRentBill(
        tenant: testTenant,
        room: testRoom,
        invoice: testInvoice,
        meterReading: testMeterReading,
        activeRoommatesCount: 2,
        propertyName: 'Krishna Residency',
        language: WhatsAppLanguage.english,
      );

      expect(text, contains('Krishna Residency - Monthly Rent Invoice'));
      expect(text, contains('Dear *Rahul Sharma*'));
      expect(text, contains('• Base Rent: ₹7,500'));
      expect(text, contains('Total Payable:* *₹8,340*'));
    });

    test('Formats Gentle Reminder template accurately', () {
      final text = WhatsAppMessageBuilder.buildGentleReminder(
        tenant: testTenant,
        room: testRoom,
        invoice: testInvoice,
        propertyName: 'Krishna Residency',
        upiVpa: 'landlord@oksbi',
        language: WhatsAppLanguage.hinglish,
      );

      expect(text, contains('Gentle Rent Reminder'));
      expect(text, contains('Namaste *Rahul Sharma* ji!'));
      expect(text, contains('₹8,340'));
      expect(text, contains('upi://pay?pa=landlord@oksbi'));
    });

    test('Formats Overdue Rent Notice template accurately', () {
      final overdueInv = testInvoice.copyWith(status: InvoiceStatus.overdue);

      final text = WhatsAppMessageBuilder.buildOverdueNotice(
        tenant: testTenant,
        room: testRoom,
        invoice: overdueInv,
        propertyName: 'Krishna Residency',
        upiVpa: 'landlord@oksbi',
        language: WhatsAppLanguage.hinglish,
      );

      expect(text, contains('Overdue Rent Notice'));
      expect(text, contains('due date'));
      expect(text, contains('Pending Amount:* *₹8,340*'));
    });

    test('Formats Instant Payment Receipt Confirmation message', () {
      final payment = PaymentModel(
        id: 'pay-1',
        invoiceId: testInvoice.id,
        amount: 8340.0,
        paymentDate: DateTime(2026, 11, 3, 14, 30),
        paymentMode: PaymentMode.upi,
        receiptNumber: 'REC-2026-0001',
        transactionRef: 'UPI-9082049182',
      );

      final text = WhatsAppMessageBuilder.buildPaymentReceiptConfirmation(
        tenant: testTenant,
        room: testRoom,
        payment: payment,
        remainingBalance: 0.0,
        propertyName: 'Krishna Residency',
        language: WhatsAppLanguage.hinglish,
      );

      expect(text, contains('Payment Receipt - Krishna Residency'));
      expect(text, contains('Amount Received:* *₹8,340*'));
      expect(text, contains('Receipt #:* REC-2026-0001'));
      expect(text, contains('Mode:* UPI'));
      expect(text, contains('Ref / UTR:* UPI-9082049182'));
      expect(text, contains('All Dues Settled (₹0 Balance)'));
    });
  });

  group('Step 9 Audit: SendReminderSheet Widget Tests', () {
    testWidgets('SendReminderSheet renders templates, language switcher, and action buttons', (tester) async {
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
              body: SendReminderSheet(
                invoice: inv,
                tenant: ob1.tenant,
                room: r1,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Send WhatsApp Bill'), findsOneWidget);
      expect(find.text('Aryan Mehta • Room 101'), findsOneWidget);
      expect(find.text('Monthly Bill (बिल)'), findsOneWidget);
      expect(find.text('Gentle Reminder (याद दिलाना)'), findsOneWidget);
      expect(find.text('Overdue Notice (बकाया)'), findsOneWidget);
      expect(find.textContaining('Open WhatsApp & Send to 9829011111'), findsOneWidget);
      expect(find.text('Copy Message Text to Clipboard'), findsOneWidget);

      // Switch to Gentle Reminder
      await tester.tap(find.text('Gentle Reminder (याद दिलाना)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Gentle Rent Reminder'), findsOneWidget);

      // Switch Language to English
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dear *Aryan Mehta*'), findsOneWidget);
    });
  });
}
