import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../invoice/models/invoice_model.dart';
import '../../meter/models/meter_reading_model.dart';
import '../../payment/models/payment_model.dart';
import '../../property/models/property_model.dart';
import '../../room/models/room_model.dart';
import '../../tenant/models/tenant_model.dart';
import '../domain/pdf_receipt_generator.dart';

/// Screen displaying a live on-device vector preview of the official PDF rent receipt
/// with built-in printing, WhatsApp/PDF sharing, and zoom controls.
class ReceiptPreviewScreen extends StatelessWidget {
  final PropertyModel property;
  final RoomModel room;
  final TenantModel tenant;
  final InvoiceModel invoice;
  final PaymentModel payment;
  final MeterReadingModel? meterReading;

  const ReceiptPreviewScreen({
    super.key,
    required this.property,
    required this.room,
    required this.tenant,
    required this.invoice,
    required this.payment,
    this.meterReading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt: ${payment.receiptNumber}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              '${tenant.fullName} • Room ${room.roomNumber}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: PdfPreview(
        build: (format) => PdfReceiptGenerator.generateReceiptPdf(
          property: property,
          room: room,
          tenant: tenant,
          invoice: invoice,
          payment: payment,
          meterReading: meterReading,
        ),
        initialPageFormat: PdfPageFormat.a4,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: 'Rent_Receipt_${payment.receiptNumber}.pdf',
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Generating Vector PDF Receipt...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
