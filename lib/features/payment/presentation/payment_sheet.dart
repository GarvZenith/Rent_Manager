import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/rent_khata_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../invoice/models/invoice_model.dart';
import '../../room/presentation/quick_payment_dialog.dart';
import '../domain/upi_uri_builder.dart';
import 'widgets/upi_qr_widget.dart';

/// Modal bottom sheet or dialog to display dynamic NPCI UPI QR code
/// and launch installed UPI payment apps directly.
class PaymentSheet extends ConsumerWidget {
  final InvoiceModel invoice;
  final String roomNumber;
  final String tenantName;

  const PaymentSheet({
    super.key,
    required this.invoice,
    required this.roomNumber,
    required this.tenantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rentKhataRepositoryProvider);
    final room = state.rooms.firstWhere(
      (r) => r.id == invoice.roomId,
      orElse: () => throw StateError('Room not found for payment sheet'),
    );
    final property = state.properties.isNotEmpty ? state.properties.first : null;

    final effectiveVpa = property?.upiVpa ?? 'rentkhata.merchant@oksbi';
    final effectivePayeeName = property?.upiAccountName ?? (property?.name ?? 'RentKhata Landlord');
    final amountToPay = invoice.balanceDue > 0 ? invoice.balanceDue : invoice.totalAmount;
    final note = 'Rent-Room$roomNumber-${invoice.billingMonth}';

    final upiUriString = UpiUriBuilder.buildUriString(
      upiId: effectiveVpa,
      payeeName: effectivePayeeName,
      amount: amountToPay,
      transactionNote: note,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Sheet Title & Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instant UPI Payment',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      Text(
                        'Room $roomNumber • $tenantName',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 18),

            // Dynamic UPI QR Code
            UpiQrWidget(
              upiUri: upiUriString,
              amount: amountToPay,
              payeeName: effectivePayeeName,
              upiVpa: effectiveVpa,
              transactionNote: note,
            ),
            const SizedBox(height: 16),

            // Launch UPI App Button (GPay / PhonePe / Paytm Intent)
            AppButton(
              label: '⚡ Open UPI App (${CurrencyFormatter.format(amountToPay)})',
              icon: Icons.launch_rounded,
              onPressed: () async {
                final success = await UpiUriBuilder.launchUpi(
                  upiId: effectiveVpa,
                  payeeName: effectivePayeeName,
                  amount: amountToPay,
                  transactionNote: note,
                );

                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No UPI app found. Please scan the QR code with GPay/PhonePe.'),
                      backgroundColor: AppColors.statusOverdue,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // Copy Payment Link / Web Bridge
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: AppColors.primary),
              ),
              icon: const Icon(Icons.link_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Copy Direct UPI Payment Link',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: upiUriString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('UPI Intent link copied!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Record Manual / Cash Settlement option
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (ctx) => QuickPaymentDialog(
                    invoice: invoice,
                    roomNumber: room.roomNumber,
                  ),
                );
              },
              icon: const Icon(Icons.payments_outlined, size: 16, color: AppColors.textSecondary),
              label: const Text(
                'Received Cash instead? Record Payment Here',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
