import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/rent_khata_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../room/presentation/quick_payment_dialog.dart';
import '../../payment/presentation/payment_sheet.dart';
import '../models/invoice_model.dart';

/// Screen displaying the full itemized breakdown of a monthly rent bill
class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rentKhataRepositoryProvider);
    final repo = ref.read(rentKhataRepositoryProvider.notifier);

    // Find invoice from state
    final invoice = state.invoices.firstWhere(
      (inv) => inv.id == invoiceId,
      orElse: () => throw StateError('Invoice not found: $invoiceId'),
    );

    // Tenant, Room & Lease info
    final tenant = state.tenants.firstWhere(
      (t) => t.id == invoice.tenantId,
      orElse: () => throw StateError('Tenant not found for invoice'),
    );
    final room = state.rooms.firstWhere(
      (r) => r.id == invoice.roomId,
      orElse: () => throw StateError('Room not found for invoice'),
    );
    final payments = state.payments.where((p) => p.invoiceId == invoice.id).toList();

    final dateFormat = DateFormat('dd MMM yyyy');
    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(invoice.billingYear, invoice.billingMonth),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              '$monthName • Room ${room.roomNumber}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: StatusBadge(
                status: _getBadgeStatus(invoice),
                label: _getBadgeLabel(invoice),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tenant Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        tenant.fullName.isNotEmpty ? tenant.fullName[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenant.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '📱 ${tenant.phone} • Room ${room.roomNumber}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (tenant.workplaceOrCollege != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              tenant.workplaceOrCollege!,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Billing Period & Dates Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Billing Period (बिल महीना):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          monthName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 35, color: AppColors.border),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Date (अंतिम तिथि):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(invoice.dueDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: invoice.balanceDue > 0 && DateTime.now().isAfter(invoice.dueDate)
                                ? AppColors.statusOverdue
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Itemized Bill Breakdown Card
            const Text(
              'Itemized Breakdown (विस्तृत विवरण):',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLineItem(
                      label: 'Base Rent (कमरा किराया)',
                      amount: invoice.baseRent,
                    ),
                    if (invoice.electricityCharges > 0) ...[
                      const Divider(height: 16),
                      _buildLineItem(
                        label: 'Electricity / Sub-Meter (बिजली बिल)',
                        amount: invoice.electricityCharges,
                        highlightColor: AppColors.primary,
                      ),
                    ],
                    if (invoice.maintenanceCharges > 0) ...[
                      const Divider(height: 16),
                      _buildLineItem(
                        label: 'Maintenance Charges (रखरखाव)',
                        amount: invoice.maintenanceCharges,
                      ),
                    ],
                    if (invoice.foodMessCharges > 0) ...[
                      const Divider(height: 16),
                      _buildLineItem(
                        label: 'Food / Mess Charges (मेस खर्च)',
                        amount: invoice.foodMessCharges,
                      ),
                    ],
                    if (invoice.otherCharges > 0) ...[
                      const Divider(height: 16),
                      _buildLineItem(
                        label: 'Previous Arrears / Other (पिछला बकाया)',
                        amount: invoice.otherCharges,
                        highlightColor: AppColors.statusOverdue,
                      ),
                    ],
                    if (invoice.lateFee > 0) ...[
                      const Divider(height: 16),
                      _buildLineItem(
                        label: 'Late Fee (विलंब शुल्क)',
                        amount: invoice.lateFee,
                        highlightColor: AppColors.statusOverdue,
                      ),
                    ],
                    if (invoice.discountAmount > 0) ...[
                      const Divider(height: 16),
                      _buildLineItem(
                        label: 'Discount / Concession (छूट)',
                        amount: -invoice.discountAmount,
                        highlightColor: AppColors.statusPaid,
                      ),
                    ],
                    const Divider(height: 24, thickness: 1.2),

                    // Total Billed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Grand Total Billed (कुल बिल):',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(invoice.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Amount Paid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Amount Paid (जमा राशि):',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(invoice.amountPaid),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.statusPaid),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Net Balance Due
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Balance Due (बकाया राशि):',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(invoice.balanceDue),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            color: invoice.balanceDue > 0 ? AppColors.statusOverdue : AppColors.statusPaid,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payments Received History
            if (payments.isNotEmpty) ...[
              const Text(
                'Payment Transactions (भुगतान रसीदें):',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ...payments.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.statusPaid),
                                    const SizedBox(width: 6),
                                    Text(
                                      p.receiptNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dateFormat.format(p.paymentDate)} • ${p.paymentMode.name.toUpperCase()} ${p.transactionRef != null ? "(${p.transactionRef})" : ""}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(p.amount),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.statusPaid),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (invoice.balanceDue > 0) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(
                  '⚡ Show UPI QR / Pay Online (${CurrencyFormatter.format(invoice.balanceDue)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => PaymentSheet(
                      invoice: invoice,
                      roomNumber: room.roomNumber,
                      tenantName: tenant.fullName,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Record Cash / Offline Payment (रुपये जमा करें)',
                icon: Icons.payments_outlined,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => QuickPaymentDialog(
                      invoice: invoice,
                      roomNumber: room.roomNumber,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            // Copy WhatsApp Bill Summary Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final summary = _formatWhatsAppBill(invoice, tenant, room, monthName, dateFormat);
                Clipboard.setData(ClipboardData(text: summary));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('WhatsApp Rent Bill copied to clipboard!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 18),
              label: const Text(
                'Copy WhatsApp Rent Bill Text',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),

            // Quick status toggle actions
            Row(
              children: [
                if (invoice.status != InvoiceStatus.paid)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        repo.updateInvoiceStatus(invoice.id, InvoiceStatus.paid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invoice marked as Settled / Paid')),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.statusPaid),
                      label: const Text('Mark Paid', style: TextStyle(color: AppColors.statusPaid, fontSize: 12)),
                    ),
                  ),
                if (invoice.status != InvoiceStatus.overdue && invoice.balanceDue > 0)
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        repo.updateInvoiceStatus(invoice.id, InvoiceStatus.overdue);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invoice marked as Overdue')),
                        );
                      },
                      icon: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.statusOverdue),
                      label: const Text('Mark Overdue', style: TextStyle(color: AppColors.statusOverdue, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem({
    required String label,
    required double amount,
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlightColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  RoomPaymentStatus _getBadgeStatus(InvoiceModel invoice) {
    if (invoice.status == InvoiceStatus.paid || invoice.isFullyPaid) {
      return RoomPaymentStatus.paid;
    }
    if (invoice.status == InvoiceStatus.overdue ||
        (invoice.balanceDue > 0 && DateTime.now().isAfter(invoice.dueDate))) {
      return RoomPaymentStatus.overdue;
    }
    return RoomPaymentStatus.dueToday;
  }

  String _getBadgeLabel(InvoiceModel invoice) {
    if (invoice.status == InvoiceStatus.paid || invoice.isFullyPaid) {
      return 'Paid';
    }
    if (invoice.status == InvoiceStatus.overdue ||
        (invoice.balanceDue > 0 && DateTime.now().isAfter(invoice.dueDate))) {
      return 'Overdue';
    }
    return 'Due';
  }

  String _formatWhatsAppBill(
    InvoiceModel invoice,
    tenant,
    room,
    String monthName,
    DateFormat dateFormat,
  ) {
    final sb = StringBuffer();
    sb.writeln('📋 *Rent Bill / किराया चालान - $monthName*');
    sb.writeln('-----------------------------------');
    sb.writeln('👤 *Tenant:* ${tenant.fullName}');
    sb.writeln('🚪 *Room:* ${room.roomNumber}');
    sb.writeln('📄 *Invoice #:* ${invoice.invoiceNumber}');
    sb.writeln('📅 *Due Date:* ${dateFormat.format(invoice.dueDate)}');
    sb.writeln('-----------------------------------');
    sb.writeln('• Base Rent: ${CurrencyFormatter.format(invoice.baseRent)}');
    if (invoice.electricityCharges > 0) {
      sb.writeln('• Electricity: ${CurrencyFormatter.format(invoice.electricityCharges)}');
    }
    if (invoice.maintenanceCharges > 0) {
      sb.writeln('• Maintenance: ${CurrencyFormatter.format(invoice.maintenanceCharges)}');
    }
    if (invoice.foodMessCharges > 0) {
      sb.writeln('• Food/Mess: ${CurrencyFormatter.format(invoice.foodMessCharges)}');
    }
    if (invoice.otherCharges > 0) {
      sb.writeln('• Arrears/Previous: ${CurrencyFormatter.format(invoice.otherCharges)}');
    }
    if (invoice.lateFee > 0) {
      sb.writeln('• Late Fee: ${CurrencyFormatter.format(invoice.lateFee)}');
    }
    if (invoice.discountAmount > 0) {
      sb.writeln('• Discount: -${CurrencyFormatter.format(invoice.discountAmount)}');
    }
    sb.writeln('-----------------------------------');
    sb.writeln('*Total Billed:* ${CurrencyFormatter.format(invoice.totalAmount)}');
    sb.writeln('*Paid:* ${CurrencyFormatter.format(invoice.amountPaid)}');
    sb.writeln('*Balance Due:* ${CurrencyFormatter.format(invoice.balanceDue)}');
    sb.writeln('-----------------------------------');
    sb.writeln('Please pay before due date to avoid late fees. Thank you!');
    return sb.toString();
  }
}
