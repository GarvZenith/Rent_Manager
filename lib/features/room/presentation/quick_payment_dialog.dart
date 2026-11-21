import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../invoice/models/invoice_model.dart';
import '../../payment/models/payment_model.dart';

/// Modal dialog to record rent payments and settle invoices
class QuickPaymentDialog extends ConsumerStatefulWidget {
  final InvoiceModel invoice;
  final String roomNumber;

  const QuickPaymentDialog({
    super.key,
    required this.invoice,
    required this.roomNumber,
  });

  @override
  ConsumerState<QuickPaymentDialog> createState() => _QuickPaymentDialogState();
}

class _QuickPaymentDialogState extends ConsumerState<QuickPaymentDialog> {
  late final TextEditingController _amountController;
  final _refController = TextEditingController();
  PaymentMode _paymentMode = PaymentMode.upi;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.balanceDue.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _record() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    final refNo = _refController.text.trim().isEmpty ? null : _refController.text.trim();

    ref.read(rentKhataRepositoryProvider.notifier).recordPayment(
          invoiceId: widget.invoice.id,
          amount: amount,
          mode: _paymentMode,
          transactionRef: refNo,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment of ${CurrencyFormatter.format(amount)} recorded successfully!'),
        backgroundColor: AppColors.statusPaid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settle Payment - Room ${widget.roomNumber}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Invoice: ${widget.invoice.invoiceNumber}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 20),

            // Due Amount Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusOverdueLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusOverdue.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pending Balance (बाकी राशि):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    CurrencyFormatter.format(widget.invoice.balanceDue),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.statusOverdue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Amount Received Field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Amount Received (प्राप्त राशि ₹)',
                prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.statusPaid),
              ),
            ),
            const SizedBox(height: 14),

            // Payment Mode Selector
            const Text('Payment Mode (भुगतान का तरीका):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<PaymentMode>(
              initialValue: _paymentMode,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payment_rounded),
              ),
              items: const [
                DropdownMenuItem(value: PaymentMode.upi, child: Text('UPI (GPay / PhonePe / Paytm)')),
                DropdownMenuItem(value: PaymentMode.cash, child: Text('Cash (नकद)')),
                DropdownMenuItem(value: PaymentMode.bankTransfer, child: Text('Bank Transfer (NEFT / IMPS)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _paymentMode = val);
              },
            ),
            const SizedBox(height: 14),

            // UTR / Reference
            TextField(
              controller: _refController,
              decoration: const InputDecoration(
                labelText: 'UTR / Transaction Reference (Optional)',
                hintText: 'e.g. 408291849182',
                prefixIcon: Icon(Icons.receipt_long_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Button
            AppButton(
              label: 'Confirm & Save Payment',
              icon: Icons.check_circle_rounded,
              onPressed: _record,
            ),
          ],
        ),
      ),
    );
  }
}
