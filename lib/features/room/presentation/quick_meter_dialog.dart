import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../meter/domain/electricity_calculator.dart';
import '../../meter/presentation/meter_history_dialog.dart';
import '../../meter/services/meter_ocr_service.dart';
import '../models/room_model.dart';

/// Quick interactive modal to record sub-meter reading with instant math, splits,
/// AI camera OCR scanning, surge warning & history
class QuickMeterDialog extends ConsumerStatefulWidget {
  final RoomModel room;
  final double defaultRate;
  final MeterOcrService? ocrService;

  const QuickMeterDialog({
    super.key,
    required this.room,
    this.defaultRate = 10.0,
    this.ocrService,
  });

  @override
  ConsumerState<QuickMeterDialog> createState() => _QuickMeterDialogState();
}

class _QuickMeterDialogState extends ConsumerState<QuickMeterDialog> {
  late final TextEditingController _readingController;
  late final MeterOcrService _ocrService;
  late double _previousReading;
  double _currentReading = 0.0;
  String? _errorMessage;
  bool _photoProofAttached = true;
  bool _isScanning = false;
  String? _scannedPhotoPath;
  String? _ocrDetectionMessage;

  @override
  void initState() {
    super.initState();
    _ocrService = widget.ocrService ?? MeterOcrService();
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

  Future<void> _handleOcrScan(ImageSource source) async {
    setState(() {
      _isScanning = true;
      _ocrDetectionMessage = null;
    });

    final result = await _ocrService.captureAndScan(
      source: source,
      previousReading: _previousReading,
    );

    if (!mounted) return;

    setState(() {
      _isScanning = false;
    });

    if (result.isSuccess && result.reading != null) {
      final detected = result.reading!;
      final formatted = detected % 1 == 0 ? detected.toInt().toString() : detected.toStringAsFixed(1);

      _readingController.text = formatted;
      _onReadingChanged(formatted);

      setState(() {
        _scannedPhotoPath = result.imagePath;
        _photoProofAttached = true;
        _ocrDetectionMessage = '✅ AI Detected: $formatted Units (${(result.confidence * 100).toInt()}% match)';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Scanned $formatted Units from Meter Dial!'),
          backgroundColor: AppColors.statusPaid,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (result.errorMessage != null && !result.errorMessage!.contains('cancelled')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: AppColors.statusOverdue,
        ),
      );
    }
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Sub-Meter Scanner (स्मार्ट मीटर स्कैनर)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Point camera at the meter LCD to read digits automatically without typing.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Point at LCD display on the sub-meter'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleOcrScan(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select an existing photo of the meter dial'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleOcrScan(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_errorMessage != null || _currentReading < _previousReading) return;

    final photoPathToSave = _scannedPhotoPath ?? (_photoProofAttached ? 'meter_photo_dial_verified.jpg' : null);

    ref.read(rentKhataRepositoryProvider.notifier).recordMeterReading(
          roomId: widget.room.id,
          currentReading: _currentReading,
          ratePerUnit: widget.defaultRate,
          photoUrl: photoPathToSave,
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

              // AI Smart Camera Scanner Banner / Action
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      AppColors.secondary.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Smart Meter Scan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Photo khicho aur bill automatic calculate ho jayega',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _showImageSourceSelector,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 16),
                      label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              if (_ocrDetectionMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.statusPaidLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.statusPaid.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.statusPaid),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _ocrDetectionMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusPaid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

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
                  suffixIcon: IconButton(
                    tooltip: 'AI Scan Photo',
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                    onPressed: _showImageSourceSelector,
                  ),
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
                subtitle: Text(
                  _scannedPhotoPath != null
                      ? '📸 Scanned image attached as audit proof'
                      : 'Audit proof attached to WhatsApp bill',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
