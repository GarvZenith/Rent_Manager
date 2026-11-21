import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../invoice/models/invoice_model.dart';
import '../../meter/models/meter_reading_model.dart';
import '../../payment/models/payment_model.dart';
import '../../property/models/property_model.dart';
import '../../room/models/room_model.dart';
import '../../tenant/models/tenant_model.dart';
import '../domain/pdf_receipt_generator.dart';
import '../presentation/receipt_preview_screen.dart';

/// Service providing native printing, WhatsApp sharing, and preview for PDF rent receipts.
class PdfSharingService {
  /// Launches native OS print dialog
  static Future<void> printReceipt({
    required Uint8List pdfBytes,
    required String receiptNumber,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'Rent_Receipt_$receiptNumber',
    );
  }

  /// Launches system share sheet (WhatsApp, Email, Drive, etc.)
  static Future<void> shareReceipt({
    required Uint8List pdfBytes,
    required String receiptNumber,
  }) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Rent_Receipt_$receiptNumber.pdf',
    );
  }

  /// Opens the receipt preview screen
  static void openReceiptPreview(
    BuildContext context, {
    required PropertyModel property,
    required RoomModel room,
    required TenantModel tenant,
    required InvoiceModel invoice,
    required PaymentModel payment,
    MeterReadingModel? meterReading,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ReceiptPreviewScreen(
          property: property,
          room: room,
          tenant: tenant,
          invoice: invoice,
          payment: payment,
          meterReading: meterReading,
        ),
      ),
    );
  }

  /// Generates receipt PDF bytes on demand
  static Future<Uint8List> generateBytes({
    required PropertyModel property,
    required RoomModel room,
    required TenantModel tenant,
    required InvoiceModel invoice,
    required PaymentModel payment,
    MeterReadingModel? meterReading,
  }) {
    return PdfReceiptGenerator.generateReceiptPdf(
      property: property,
      room: room,
      tenant: tenant,
      invoice: invoice,
      payment: payment,
      meterReading: meterReading,
    );
  }
}
