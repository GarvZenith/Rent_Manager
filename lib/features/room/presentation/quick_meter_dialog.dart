import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../models/room_model.dart';

/// Quick interactive modal to record sub-meter reading with instant math calculation
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
        _errorMessage = 'New reading cannot be less than previous ($_previousReading)';
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
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unitsConsumed = _currentReading >= _previousReading ? _currentReading - _previousReading : 0.0;
    final totalCost = unitsConsumed * widget.defaultRate;

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
                      'Room ${widget.room.roomNumber} - Meter Reading',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'बिजली मीटर रीडिंग दर्ज करें',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

            // Previous Reading Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Previous Reading (पिछली रीडिंग):', style: TextStyle(fontSize: 13)),
                  Text(
                    '${_previousReading.toStringAsFixed(0)} Units',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

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
            const SizedBox(height: 16),

            // Live Calculation Card
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
                      const Text('Units Consumed (खर्च यूनिट्स):', style: TextStyle(fontSize: 13)),
                      Text(
                        '${unitsConsumed.toStringAsFixed(0)} Units',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tariff Rate (दर):', style: const TextStyle(fontSize: 13)),
                      Text('₹${widget.defaultRate.toStringAsFixed(0)} / Unit', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Electricity Bill:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        CurrencyFormatter.format(totalCost),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.statusOverdue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            AppButton(
              label: 'Save & Update Reading',
              icon: Icons.check_circle_rounded,
              onPressed: _errorMessage == null ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
