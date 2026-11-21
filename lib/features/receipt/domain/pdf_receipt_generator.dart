import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../invoice/models/invoice_model.dart';
import '../../meter/models/meter_reading_model.dart';
import '../../payment/models/payment_model.dart';
import '../../property/models/property_model.dart';
import '../../room/models/room_model.dart';
import '../../tenant/models/tenant_model.dart';

/// High-performance on-device vector PDF generator for official rent receipts,
/// HRA tax compliance, and payment acknowledgments.
class PdfReceiptGenerator {
  /// Generates a single-page, pixel-perfect A4 vector PDF document for a payment
  static Future<Uint8List> generateReceiptPdf({
    required PropertyModel property,
    required RoomModel room,
    required TenantModel tenant,
    required InvoiceModel invoice,
    required PaymentModel payment,
    MeterReadingModel? meterReading,
  }) async {
    final pdf = pw.Document(
      title: 'Rent Receipt - ${payment.receiptNumber}',
      author: property.name,
    );

    final dateFormat = DateFormat('dd MMM yyyy');
    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(invoice.billingYear, invoice.billingMonth),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==============================================================
              // 1. HEADER: Property & Receipt Title
              // ==============================================================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        property.name,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0F766E'), // Teal 700
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${property.address}, ${property.city}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        '${property.state} - ${property.pincode}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#0D9488'), // Teal 600
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'RENT PAYMENT RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Receipt No: ${payment.receiptNumber}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Date: ${dateFormat.format(payment.paymentDate)}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColor.fromHex('#0D9488')),
              pw.SizedBox(height: 12),

              // ==============================================================
              // 2. TENANT & ROOM DETAILS CARD
              // ==============================================================
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RECEIVED WITH THANKS FROM:',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          tenant.fullName,
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Mobile: +91 ${tenant.phone}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (tenant.workplaceOrCollege != null)
                          pw.Text('Institution: ${tenant.workplaceOrCollege}',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('ACCOMMODATION DETAILS:',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Room No: ${room.roomNumber}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F766E')),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Billing Period: $monthName',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.Text('Invoice Ref: ${invoice.invoiceNumber}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ==============================================================
              // 3. ITEMIZED CHARGES BREAKDOWN TABLE
              // ==============================================================
              pw.Text(
                'PAYMENT & BILL BREAKDOWN',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                    children: [
                      _buildTableCell('Particulars / Description', isHeader: true),
                      _buildTableCell('Calculation Details', isHeader: true),
                      _buildTableCell('Amount (Rs.)', isHeader: true, alignRight: true),
                    ],
                  ),
                  // Base Rent
                  pw.TableRow(
                    children: [
                      _buildTableCell('Monthly Room Rent'),
                      _buildTableCell('Agreed monthly license fee'),
                      _buildTableCell(_formatAmount(invoice.baseRent), alignRight: true),
                    ],
                  ),
                  // Electricity Sub-Meter
                  if (invoice.electricityCharges > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Electricity Sub-Meter Charges'),
                        _buildTableCell(meterReading != null
                            ? '${meterReading.unitsConsumed.toStringAsFixed(0)} Units @ Rs.${meterReading.ratePerUnit.toStringAsFixed(0)}/unit'
                            : 'Sub-meter consumption'),
                        _buildTableCell(_formatAmount(invoice.electricityCharges), alignRight: true),
                      ],
                    ),
                  // Maintenance
                  if (invoice.maintenanceCharges > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Maintenance / Facility Charges'),
                        _buildTableCell('Cleaning, water, security'),
                        _buildTableCell(_formatAmount(invoice.maintenanceCharges), alignRight: true),
                      ],
                    ),
                  // Food / Mess
                  if (invoice.foodMessCharges > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Mess / Food Subscription'),
                        _buildTableCell('Monthly meal plan'),
                        _buildTableCell(_formatAmount(invoice.foodMessCharges), alignRight: true),
                      ],
                    ),
                  // Arrears
                  if (invoice.otherCharges > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Previous Balance / Arrears'),
                        _buildTableCell('Carried over balance'),
                        _buildTableCell(_formatAmount(invoice.otherCharges), alignRight: true),
                      ],
                    ),
                  // Late Fee
                  if (invoice.lateFee > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Late Payment Charges'),
                        _buildTableCell('Post due date fee'),
                        _buildTableCell(_formatAmount(invoice.lateFee), alignRight: true),
                      ],
                    ),
                  // Discount
                  if (invoice.discountAmount > 0)
                    pw.TableRow(
                      children: [
                        _buildTableCell('Concession / Discount'),
                        _buildTableCell('Special concession'),
                        _buildTableCell('-${_formatAmount(invoice.discountAmount)}', alignRight: true),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ==============================================================
              // 4. TOTALS SUMMARY BOX
              // ==============================================================
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                    ),
                    child: pw.Column(
                      children: [
                        _buildSummaryRow('Total Billed Amount:', _formatAmount(invoice.totalAmount)),
                        pw.SizedBox(height: 4),
                        _buildSummaryRow(
                          'Amount Received Now:',
                          _formatAmount(payment.amount),
                          isBold: true,
                          color: PdfColor.fromHex('#16A34A'),
                        ),
                        pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#CBD5E1')),
                        _buildSummaryRow(
                          'Balance Due:',
                          _formatAmount(invoice.balanceDue),
                          isBold: true,
                          color: invoice.balanceDue > 0 ? PdfColor.fromHex('#DC2626') : PdfColor.fromHex('#16A34A'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ==============================================================
              // 5. TRANSACTION DETAILS & DIGITAL STAMP
              // ==============================================================
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Payment Mode & Reference
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PAYMENT TRANSACTION DETAILS:',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text('Payment Mode: ${payment.paymentMode.name.toUpperCase()}',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (payment.transactionRef != null)
                        pw.Text('Transaction UTR / Ref: ${payment.transactionRef}',
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      pw.Text('Timestamp: ${DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate)}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 8),
                      // HRA Tax Exemption Note
                      pw.Container(
                        width: 250,
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#EFF6FF'), // Light Blue
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE')),
                        ),
                        child: pw.Text(
                          'Valid proof of rent paid for Income Tax HRA Exemption under Sec 10(13A) of Income Tax Act 1961.',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blue800),
                        ),
                      ),
                    ],
                  ),

                  // Digital PAID Stamp & Signature Block
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Digital Stamp
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColor.fromHex('#16A34A'), width: 2),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              'PAYMENT RECEIVED',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#16A34A'),
                              ),
                            ),
                            pw.Text(
                              'Rs. ${_formatAmount(payment.amount)}',
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#16A34A'),
                              ),
                            ),
                            pw.Text(
                              'Verified by RentKhata',
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Authorized Signatory / Landlord',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        property.name,
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // ==============================================================
              // 6. FOOTER
              // ==============================================================
              pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#E2E8F0')),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated electronically via RentKhata - Property & Hostel Manager',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                  pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColors.grey800,
          ),
        ),
        pw.Text(
          'Rs. $value',
          style: pw.TextStyle(
            fontSize: isBold ? 10 : 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  static String _formatAmount(double amount) {
    // Format with Indian commas: e.g. 8,500
    final intAmount = amount.round();
    final str = intAmount.toString();
    if (str.length <= 3) return str;

    var result = str.substring(str.length - 3);
    var remaining = str.substring(0, str.length - 3);

    while (remaining.length > 2) {
      result = '${remaining.substring(remaining.length - 2)},$result';
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      result = '$remaining,$result';
    }
    return result;
  }
}
