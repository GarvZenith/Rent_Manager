import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../models/room_model.dart';

/// Modal dialog for adding a new room with sharing type and meter details
class AddRoomDialog extends ConsumerStatefulWidget {
  final String propertyId;

  const AddRoomDialog({super.key, required this.propertyId});

  @override
  ConsumerState<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends ConsumerState<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController(text: '1');
  final _rentController = TextEditingController(text: '7500');
  final _meterController = TextEditingController();
  final _initialReadingController = TextEditingController(text: '1000');
  RoomSharingType _sharingType = RoomSharingType.single;

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    _rentController.dispose();
    _meterController.dispose();
    _initialReadingController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final roomNumber = _roomNumberController.text.trim();
    final floorNumber = int.tryParse(_floorController.text.trim()) ?? 0;
    final rent = double.tryParse(_rentController.text.trim()) ?? 7500.0;
    final initialReading = double.tryParse(_initialReadingController.text.trim()) ?? 0.0;
    final subMeterNumber = _meterController.text.trim().isEmpty ? null : _meterController.text.trim();

    ref.read(rentKhataRepositoryProvider.notifier).addRoom(
          propertyId: widget.propertyId,
          roomNumber: roomNumber,
          floorNumber: floorNumber,
          sharingType: _sharingType,
          baseRentPerBed: rent,
          subMeterNumber: subMeterNumber,
          initialMeterReading: initialReading,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEng = ref.watch(languageProvider) == AppLanguage.english;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEng ? 'Add New Room' : 'Add New Room (नया कमरा)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Room Number
              TextFormField(
                controller: _roomNumberController,
                decoration: InputDecoration(
                  labelText: isEng ? 'Room Number' : 'Room Number (कमरा नं.)',
                  hintText: 'e.g. 101, 204, 302',
                  prefixIcon: const Icon(Icons.tag_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? (isEng ? 'Room number required' : 'कमरा नंबर आवश्यक है')
                    : null,
              ),
              const SizedBox(height: 12),

              // Sharing Type Selector
              Text(
                isEng ? 'Sharing Type:' : 'Sharing Type (कमरे का प्रकार):',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<RoomSharingType>(
                initialValue: _sharingType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.people_outline_rounded),
                ),
                items: [
                  DropdownMenuItem(value: RoomSharingType.single, child: Text(isEng ? 'Single (1 Bed)' : 'Single (1 Bed)')),
                  DropdownMenuItem(value: RoomSharingType.doubleSharing, child: Text(isEng ? 'Double Sharing (2 Beds)' : 'Double Sharing (2 Beds)')),
                  DropdownMenuItem(value: RoomSharingType.tripleSharing, child: Text(isEng ? 'Triple Sharing (3 Beds)' : 'Triple Sharing (3 Beds)')),
                  DropdownMenuItem(value: RoomSharingType.fullFlat, child: Text(isEng ? 'Full Flat' : 'Full Flat')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sharingType = val);
                },
              ),
              const SizedBox(height: 12),

              // Base Rent Per Bed
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isEng ? 'Monthly Rent per Bed (₹)' : 'Monthly Rent per Bed (₹) (मासिक किराया)',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
                validator: (val) {
                  final n = double.tryParse(val ?? '');
                  if (n == null || n <= 0) return isEng ? 'Valid rent amount required' : 'सही किराया राशि दर्ज करें';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Initial Meter Reading
              TextFormField(
                controller: _initialReadingController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isEng ? 'Current Meter Reading (Units)' : 'Current Meter Reading (Units) (मीटर रीडिंग)',
                  hintText: 'e.g. 1000',
                  prefixIcon: const Icon(Icons.electric_meter_rounded),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              AppButton(
                label: isEng ? 'Save Room' : 'Save Room (कमरा जोड़ें)',
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
