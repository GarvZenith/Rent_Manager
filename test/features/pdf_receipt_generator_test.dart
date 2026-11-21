import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

import 'package:rent_manager/features/invoice/models/invoice_model.dart';
import 'package:rent_manager/features/meter/models/meter_reading_model.dart';
import 'package:rent_manager/features/payment/models/payment_model.dart';
import 'package:rent_manager/features/property/models/property_model.dart';
import 'package:rent_manager/features/receipt/domain/pdf_receipt_generator.dart';
import 'package:rent_manager/features/receipt/presentation/receipt_preview_screen.dart';
import 'package:rent_manager/features/room/models/room_model.dart';
import 'package:rent_manager/features/tenant/models/tenant_model.dart';

void main() {
  group('Step 10 Audit: PdfReceiptGenerator Domain Tests', () {
    final testProperty = PropertyModel(
      id: 'p-1',
      name: 'Krishna Residency Kota',
      address: 'Landmark City, Kunhari',
      city: 'Kota',
      state: 'Rajasthan',
      pincode: '324008',
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

    final testTenant = TenantModel(
      id: 't-1',
      fullName: 'Rahul Sharma',
      phone: '9829012345',
      workplaceOrCollege: 'Allen Career Institute Kota',
      status: TenantStatus.active,
      createdAt: DateTime(2026, 1, 1),
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
      amountPaid: 8340.0,
      status: InvoiceStatus.paid,
    );

    final testPayment = PaymentModel(
      id: 'pay-1',
      invoiceId: 'inv-1',
      amount: 8340.0,
      paymentDate: DateTime(2026, 11, 2, 11, 30),
      paymentMode: PaymentMode.upi,
      receiptNumber: 'REC-2026-0001',
      transactionRef: 'UPI-9820412891',
    );

    final testMeterReading = MeterReadingModel(
      id: 'mr-1',
      roomId: 'r-1',
      readingDate: DateTime(2026, 11, 1),
      previousReading: 1000.0,
      currentReading: 1080.0,
      ratePerUnit: 10.0,
    );

    test('Generates valid non-empty vector PDF bytes in memory', () async {
      final Uint8List pdfBytes = await PdfReceiptGenerator.generateReceiptPdf(
        property: testProperty,
        room: testRoom,
        tenant: testTenant,
        invoice: testInvoice,
        payment: testPayment,
        meterReading: testMeterReading,
      );

      // Verify non-null and valid PDF signature (%PDF-)
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));

      final headerString = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(headerString, '%PDF-');
    });

    test('Generates valid PDF for partial payment with remaining balance', () async {
      final partialInvoice = testInvoice.copyWith(
        amountPaid: 5000.0,
        status: InvoiceStatus.partiallyPaid,
      );
      final partialPayment = testPayment.copyWith(
        amount: 5000.0,
      );

      final Uint8List pdfBytes = await PdfReceiptGenerator.generateReceiptPdf(
        property: testProperty,
        room: testRoom,
        tenant: testTenant,
        invoice: partialInvoice,
        payment: partialPayment,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      expect(String.fromCharCodes(pdfBytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('Step 10 Audit: ReceiptPreviewScreen Widget Tests', () {
    testWidgets('ReceiptPreviewScreen renders AppBar and PdfPreview widget', (tester) async {
      final testProperty = PropertyModel(
        id: 'p-1',
        name: 'Kota PG',
        address: 'Kunhari',
        city: 'Kota',
        state: 'Rajasthan',
        pincode: '324008',
        createdAt: DateTime(2026, 1, 1),
      );
      final testRoom = RoomModel(
        id: 'r-1',
        propertyId: 'p-1',
        roomNumber: '102',
        floorNumber: 1,
        sharingType: RoomSharingType.single,
        baseRentPerBed: 8000.0,
      );
      final testTenant = TenantModel(
        id: 't-1',
        fullName: 'Deepak Joshi',
        phone: '9829022222',
        status: TenantStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );
      final testInvoice = InvoiceModel(
        id: 'inv-1',
        leaseId: 'l-1',
        tenantId: 't-1',
        roomId: 'r-1',
        invoiceNumber: 'INV-2026-11-102',
        billingMonth: 11,
        billingYear: 2026,
        issueDate: DateTime(2026, 11, 1),
        dueDate: DateTime(2026, 11, 5),
        baseRent: 8000.0,
        amountPaid: 8000.0,
        status: InvoiceStatus.paid,
      );
      final testPayment = PaymentModel(
        id: 'pay-1',
        invoiceId: 'inv-1',
        amount: 8000.0,
        paymentDate: DateTime(2026, 11, 2),
        paymentMode: PaymentMode.upi,
        receiptNumber: 'REC-2026-0042',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptPreviewScreen(
            property: testProperty,
            room: testRoom,
            tenant: testTenant,
            invoice: testInvoice,
            payment: testPayment,
          ),
        ),
      );

      expect(find.text('Receipt: REC-2026-0042'), findsOneWidget);
      expect(find.text('Deepak Joshi • Room 102'), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
    });
  });
}
