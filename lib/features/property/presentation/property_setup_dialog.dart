import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../models/property_model.dart';

/// Modal dialog for setting up or updating PG / Hostel Property details
class PropertySetupDialog extends ConsumerStatefulWidget {
  final PropertyModel? existingProperty;

  const PropertySetupDialog({super.key, this.existingProperty});

  @override
  ConsumerState<PropertySetupDialog> createState() => _PropertySetupDialogState();
}

class _PropertySetupDialogState extends ConsumerState<PropertySetupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _rateController;
  late final TextEditingController _upiController;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProperty;
    _nameController = TextEditingController(text: p?.name ?? '');
    _cityController = TextEditingController(text: p?.city ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _rateController = TextEditingController(
      text: p != null ? p.defaultElectricityRate.toStringAsFixed(0) : '10',
    );
    _upiController = TextEditingController(text: p?.upiVpa ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _rateController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final address = _addressController.text.trim().isEmpty ? 'Main Road' : _addressController.text.trim();
    final rate = double.tryParse(_rateController.text.trim()) ?? 10.0;
    final upi = _upiController.text.trim().isEmpty ? null : _upiController.text.trim();

    final repoNotifier = ref.read(rentKhataRepositoryProvider.notifier);

    if (widget.existingProperty != null) {
      repoNotifier.updateProperty(
        propertyId: widget.existingProperty!.id,
        name: name,
        address: address,
        city: city,
        stateName: widget.existingProperty!.state.isEmpty ? 'India' : widget.existingProperty!.state,
        pincode: widget.existingProperty!.pincode.isEmpty ? '000000' : widget.existingProperty!.pincode,
        defaultElectricityRate: rate,
        upiVpa: upi,
        upiAccountName: name,
      );
    } else {
      repoNotifier.addProperty(
        name: name,
        address: address,
        city: city,
        stateName: 'India',
        pincode: '000000',
        defaultElectricityRate: rate,
        upiVpa: upi,
        upiAccountName: name,
      );
    }

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existingProperty != null
              ? 'Property details updated!'
              : '🎉 $name setup ho gaya! Ab rooms add karein.',
        ),
        backgroundColor: AppColors.statusPaid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProperty != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isEditing ? 'Edit PG / Property' : 'Setup Your PG / Hostel',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Apne PG / Hostel ki information update karein.'
                      : 'Apne PG ka naam aur details bharein. Ye bill aur invoices par dikhai dega.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Property Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'PG / Hostel / Flat Ka Naam *',
                    hintText: 'e.g. Krishna Residency, Sharma Niwas',
                    prefixIcon: Icon(Icons.business_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Kripya apne PG ka naam dalein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // City & Electricity Rate in Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City (Shahar) *',
                          hintText: 'e.g. Kota, Delhi, Pune',
                          prefixIcon: Icon(Icons.location_city_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'City dalein';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Bijli Rate (₹/unit)',
                          hintText: '10',
                          prefixIcon: Icon(Icons.electric_bolt_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Area / Colony Address (Optional)',
                    hintText: 'e.g. Landmark City, Kunhari',
                    prefixIcon: Icon(Icons.place_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // UPI VPA for direct rent collection
                TextFormField(
                  controller: _upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID for Rent Collection (Optional)',
                    hintText: 'e.g. yourname@oksbi / paytm',
                    prefixIcon: Icon(Icons.qr_code_rounded),
                    helperText: 'Is UPI ID ka auto-QR bill par aayega',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
                AppButton(
                  label: isEditing ? 'Save Changes' : 'Property Save & Continue',
                  icon: Icons.check_circle_rounded,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
