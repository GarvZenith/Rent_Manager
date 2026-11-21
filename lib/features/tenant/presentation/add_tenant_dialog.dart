import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../room/models/room_model.dart';
import '../../room/models/bed_model.dart';

/// Comprehensive modal dialog for onboarding a new tenant with KYC & room allocation
class AddTenantDialog extends ConsumerStatefulWidget {
  final String? preselectedRoomId;
  final String? preselectedBedId;

  const AddTenantDialog({
    super.key,
    this.preselectedRoomId,
    this.preselectedBedId,
  });

  @override
  ConsumerState<AddTenantDialog> createState() => _AddTenantDialogState();
}

class _AddTenantDialogState extends ConsumerState<AddTenantDialog> {
  final _formKey = GlobalKey<FormState>();

  // Personal & Contact Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _workplaceController = TextEditingController();

  // Financial & KYC Controllers
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _idNumberController = TextEditingController();

  String? _selectedRoomId;
  String? _selectedBedId;
  String _idProofType = 'Aadhaar Card';
  bool _isDepositPaid = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(rentKhataRepositoryProvider);

    // Filter rooms that have at least one vacant bed
    final vacantRooms = state.rooms.where((r) => r.hasVacantBed).toList();

    if (widget.preselectedRoomId != null) {
      _selectedRoomId = widget.preselectedRoomId;
    } else if (vacantRooms.isNotEmpty) {
      _selectedRoomId = vacantRooms.first.id;
    }

    if (_selectedRoomId != null) {
      final room = state.rooms.firstWhere((r) => r.id == _selectedRoomId);
      final vacantBeds = room.beds.where((b) => !b.isOccupied).toList();
      if (widget.preselectedBedId != null) {
        _selectedBedId = widget.preselectedBedId;
      } else if (vacantBeds.isNotEmpty) {
        _selectedBedId = vacantBeds.first.id;
      }
      _rentController.text = room.baseRentPerBed.toStringAsFixed(0);
      _depositController.text = (room.baseRentPerBed * 2).toStringAsFixed(0); // Default 2 months deposit
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _workplaceController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  void _onRoomChanged(String? newRoomId) {
    if (newRoomId == null) return;
    final state = ref.read(rentKhataRepositoryProvider);
    final room = state.rooms.firstWhere((r) => r.id == newRoomId);
    final vacantBeds = room.beds.where((b) => !b.isOccupied).toList();

    setState(() {
      _selectedRoomId = newRoomId;
      _selectedBedId = vacantBeds.isNotEmpty ? vacantBeds.first.id : null;
      _rentController.text = room.baseRentPerBed.toStringAsFixed(0);
      _depositController.text = (room.baseRentPerBed * 2).toStringAsFixed(0);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null || _selectedBedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid Room and Bed')),
      );
      return;
    }

    final rent = double.tryParse(_rentController.text.trim()) ?? 0.0;
    final deposit = double.tryParse(_depositController.text.trim()) ?? 0.0;

    ref.read(rentKhataRepositoryProvider.notifier).onboardTenant(
          roomId: _selectedRoomId!,
          bedId: _selectedBedId!,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          guardianName: _guardianNameController.text.trim().isEmpty ? null : _guardianNameController.text.trim(),
          guardianPhone: _guardianPhoneController.text.trim().isEmpty ? null : _guardianPhoneController.text.trim(),
          workplaceOrCollege: _workplaceController.text.trim().isEmpty ? null : _workplaceController.text.trim(),
          agreedRent: rent,
          securityDeposit: deposit,
          isDepositPaid: _isDepositPaid,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tenant ${_nameController.text.trim()} onboarded successfully!'),
        backgroundColor: AppColors.statusPaid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentKhataRepositoryProvider);
    final vacantRooms = state.rooms.where((r) => r.hasVacantBed).toList();

    RoomModel? currentRoom;
    List<BedModel> availableBeds = [];
    if (_selectedRoomId != null) {
      currentRoom = state.rooms.where((r) => r.id == _selectedRoomId).firstOrNull;
      if (currentRoom != null) {
        availableBeds = currentRoom.beds.where((b) => !b.isOccupied).toList();
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Onboard Tenant (नया किरायेदार)',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Add tenant details, room bed & KYC',
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

                // Section 1: Tenant Identity
                const Text(
                  '1. Personal Details (व्यक्तिगत जानकारी)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tenant Full Name (पूरा नाम)',
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Mobile Number',
                    hintText: '10-digit mobile number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                  validator: (val) {
                    final clean = val?.replaceAll(RegExp(r'\s+'), '') ?? '';
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                      return 'Enter valid 10-digit Indian mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _workplaceController,
                  decoration: const InputDecoration(
                    labelText: 'College / Coaching / Workplace',
                    hintText: 'e.g. Allen Kota, Resonance, TCS',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2: Guardian Info (Kota/Hostel Special)
                const Text(
                  '2. Guardian / Parent Details (अभिभावक संपर्क)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _guardianNameController,
                        decoration: const InputDecoration(
                          labelText: 'Father / Guardian Name',
                          hintText: 'e.g. Suresh Sharma',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _guardianPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Guardian Phone',
                          prefixText: '+91 ',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section 3: Room & Bed Allocation
                const Text(
                  '3. Room & Bed Allocation (कमरा और बेड)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 10),

                if (vacantRooms.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusOverdueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No vacant rooms available! Please add a room or free up a bed first.',
                      style: TextStyle(color: AppColors.statusOverdue, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRoomId,
                          decoration: const InputDecoration(labelText: 'Room Number'),
                          items: vacantRooms.map((room) {
                            return DropdownMenuItem<String>(
                              value: room.id,
                              child: Text('Room ${room.roomNumber}'),
                            );
                          }).toList(),
                          onChanged: _onRoomChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBedId,
                          decoration: const InputDecoration(labelText: 'Bed Slot'),
                          items: availableBeds.map((bed) {
                            return DropdownMenuItem<String>(
                              value: bed.id,
                              child: Text(bed.bedLabel),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedBedId = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Section 4: Rent & Security Deposit
                const Text(
                  '4. Financial Terms (किराया और एडवांस डिपॉजिट)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rentController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Rent (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (val) {
                          final n = double.tryParse(val ?? '');
                          if (n == null || n <= 0) return 'Invalid rent';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _depositController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Security Deposit (₹)',
                          prefixIcon: Icon(Icons.shield_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Security Deposit Paid (एडवांस जमा हो गया)', style: TextStyle(fontSize: 13)),
                  value: _isDepositPaid,
                  onChanged: (val) => setState(() => _isDepositPaid = val),
                ),
                const SizedBox(height: 16),

                // Section 5: Digital KYC
                const Text(
                  '5. Identity Proof / KYC (पहचान पत्र)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: _idProofType,
                  decoration: const InputDecoration(labelText: 'ID Proof Type (पहचान पत्र प्रकार)'),
                  items: const [
                    DropdownMenuItem(value: 'Aadhaar Card', child: Text('Aadhaar Card')),
                    DropdownMenuItem(value: 'College/Student ID', child: Text('College ID')),
                    DropdownMenuItem(value: 'Voter ID', child: Text('Voter ID')),
                    DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _idProofType = val);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _idNumberController,
                  decoration: const InputDecoration(
                    labelText: 'ID Number (Optional)',
                    hintText: 'e.g. XXXX-XXXX-1234',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Onboard Submit Button
                AppButton(
                  label: 'Complete Onboarding (किरायेदार जोड़ें)',
                  icon: Icons.person_add_rounded,
                  onPressed: vacantRooms.isNotEmpty ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
