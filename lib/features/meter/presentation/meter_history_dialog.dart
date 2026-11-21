import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../room/models/room_model.dart';
import '../domain/electricity_calculator.dart';

/// Modal dialog showing chronological sub-meter readings, monthly trends & mathematical proof
class MeterHistoryDialog extends ConsumerWidget {
  final RoomModel room;
  final double ratePerUnit;

  const MeterHistoryDialog({
    super.key,
    required this.room,
    this.ratePerUnit = 10.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rentKhataRepositoryProvider);
    final readings = state.meterReadings
        .where((r) => r.roomId == room.id)
        .toList()
        .reversed
        .toList();

    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Room ${room.roomNumber} - Meter History',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Sub-Meter: ${room.subMeterNumber ?? "Default"} • ₹$ratePerUnit/unit',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Current Dial Reading Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Current Dial Reading (वर्तमान रीडिंग):', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.primary),
                        Text(
                          '${room.currentMeterReading.toStringAsFixed(0)} Units',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Chronological History List
              const Text(
                'Reading History & Audit Trail (पिछला रिकॉर्ड):',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: readings.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.electric_meter_outlined, size: 40, color: AppColors.textMuted),
                              const SizedBox(height: 8),
                              const Text(
                                'No previous meter records yet for this room.\nEnter readings to see audit history.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: readings.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final r = readings[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFormat.format(r.readingDate),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(r.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.statusOverdue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${r.previousReading.toStringAsFixed(0)} ➔ ${r.currentReading.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        '${r.unitsConsumed.toStringAsFixed(0)} Units (@ ₹${r.ratePerUnit.toStringAsFixed(0)})',
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Copy Math button for WhatsApp
                                InkWell(
                                  onTap: () {
                                    final breakdown = ElectricityCalculator.calculate(
                                      previousReading: r.previousReading,
                                      currentReading: r.currentReading,
                                      ratePerUnit: r.ratePerUnit,
                                      activeTenantsCount: room.occupiedBedCount,
                                    );
                                    final text = breakdown.toWhatsAppMathString(roomNumber: room.roomNumber);
                                    Clipboard.setData(ClipboardData(text: text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('WhatsApp Math Proof copied to clipboard!'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Copy WhatsApp Math Proof',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
