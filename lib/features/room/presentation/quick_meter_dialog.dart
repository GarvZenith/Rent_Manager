import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../meter/domain/electricity_calculator.dart';
import '../../meter/presentation/meter_history_dialog.dart';
import '../models/room_model.dart';

/// Quick interactive modal to record sub-meter reading with instant math, splits, surge warning & history
class QuickMeterDialog extends ConsumerStatefulWidget {
  final RoomModel room;
  final double defaultRate;

  const QuickMeterDialog({
    super.key,
    required this.room,
    this.defaultRate = 10.0,
  });

  @override
  ConsumerState<QuickMeterDialog> createState() => _QuickMeterDialogState();
}

class _QuickMeterDialogState extends ConsumerState<QuickMeterDialog> {
  late final TextEditingController _readingController;
  late double _previousReading;
  double _currentReading = 0.0;
  String? _errorMessage;
  bool _photoProofAttached = true; // Default simulated photo attachment

  @override
  void initState() {
    super.initState();
    _previousReading = widget.room.currentMeterReading;
    _currentReading = _previousReading;
    _readingController = TextEditingController(text: _previousReading.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _readingController.dispose();
    super.dispose();
  }

  void _onReadingChanged(String val) {
    final parsed = double.tryParse(val.trim());
    setState(() {
      if (parsed == null) {
        _errorMessage = 'Invalid reading number';
        _currentReading = _previousReading;
      } else if (parsed < _previousReading) {
        _errorMessage = 'New reading cannot be less than previous (${_previousReading.toStringAsFixed(0)})';
        _currentReading = parsed;
      } else {
        _errorMessage = null;
        _currentReading = parsed;
      }
    });
  }

  void _save() {
    if (_errorMessage != null || _currentReading < _previousReading) return;

    ref.read(rentKhataRepositoryProvider.notifier).recordMeterReading(
          roomId: widget.room.id,
          currentReading: _currentReading,
          ratePerUnit: widget.defaultRate,
          photoUrl: _photoProofAttached ? 'meter_photo_dial_verified.jpg' : null,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meter reading for Room ${widget.room.roomNumber} updated to ${_currentReading.toStringAsFixed(0)} units!'),
        backgroundColor: AppColors.statusPaid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentKhataRepositoryProvider);
    final previousReadings = state.meterReadings.where((r) => r.roomId == widget.room.id).toList();
    final lastCycleUnits = previousReadings.isNotEmpty ? previousReadings.last.unitsConsumed : null;

    ElectricityBillBreakdown? breakdown;
    if (_currentReading >= _previousReading) {
      breakdown = ElectricityCalculator.calculate(
        previousReading: _previousReading,
        currentReading: _currentReading,
        ratePerUnit: widget.defaultRate,
        activeTenantsCount: widget.room.occupiedBedCount,
        lastCycleUnitsConsumed: lastCycleUnits,
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${widget.room.roomNumber} - Meter Reading',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'बिजली मीटर रीडिंग दर्ज करें (Dispute-Proof)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              const Divider(height: 20),

              // Previous Reading Display & History Link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Last Dial: ${_previousReading.toStringAsFixed(0)} Units',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => MeterHistoryDialog(
                          room: widget.room,
                          ratePerUnit: widget.defaultRate,
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('View History', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Current Reading Input
              TextField(
                controller: _readingController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Enter Current Reading (नयी रीडिंग)',
                  prefixIcon: const Icon(Icons.flash_on_rounded, color: AppColors.primary),
                  errorText: _errorMessage,
                ),
                onChanged: _onReadingChanged,
              ),
              const SizedBox(height: 14),

              // Live Mathematical Proof Card
              if (breakdown != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Units Consumed (खर्च यूनिट्स):', style: TextStyle(fontSize: 13)),
                          ),
                          Text(
                            '${breakdown.unitsConsumed.toStringAsFixed(0)} Units',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Tariff Rate (दर):', style: TextStyle(fontSize: 13)),
                          ),
                          Text('₹${widget.defaultRate.toStringAsFixed(0)} / Unit', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      if (breakdown.activeTenantsCount > 1) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Split (${breakdown.activeTenantsCount} Roommates):', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ),
                            Text(
                              '${CurrencyFormatter.format(breakdown.perTenantAmount)} / student',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Total Room Electricity Bill:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          Text(
                            CurrencyFormatter.format(breakdown.totalRoomAmount),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.statusOverdue),
                          ),
                        ],
                      ),

                      // Surge Anomaly Warning
                      if (breakdown.isSurgeWarning) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.statusOverdueLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.statusOverdue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Surge Alert: ${breakdown.surgePercentage.toStringAsFixed(0)}% jump from last month! Check AC/heater.',
                                  style: const TextStyle(fontSize: 11, color: AppColors.statusOverdue, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Photo Dial Attachment Toggle
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                secondary: const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.primary),
                title: const Text(
                  'Attach Meter Dial Photo Proof',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Audit proof attached to WhatsApp bill',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                value: _photoProofAttached,
                onChanged: (val) => setState(() => _photoProofAttached = val ?? true),
              ),
              const SizedBox(height: 16),

              // Submit Button
              AppButton(
                label: 'Save & Update Reading',
                icon: Icons.check_circle_rounded,
                onPressed: _errorMessage == null ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
