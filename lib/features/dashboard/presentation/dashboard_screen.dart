import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/rent_khata_repository.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../invoice/models/invoice_model.dart';
import '../../room/models/room_model.dart';
import '../../room/presentation/add_room_dialog.dart';
import '../../room/presentation/quick_meter_dialog.dart';
import '../../room/presentation/quick_payment_dialog.dart';
import '../../room/presentation/widgets/room_card.dart';
import '../../tenant/presentation/add_tenant_dialog.dart';
import '../../tenant/presentation/tenant_profile_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _loadSamplePGData(WidgetRef ref) {
    final repo = ref.read(rentKhataRepositoryProvider.notifier);

    // 1. Create Property
    final property = repo.addProperty(
      name: 'Krishna Residency',
      address: 'Landmark City, Kunhari',
      city: 'Kota',
      stateName: 'Rajasthan',
      pincode: '324008',
      defaultElectricityRate: 10.0,
      upiVpa: 'sharmaji@oksbi',
      upiAccountName: 'Ramesh Sharma',
    );

    // 2. Room 101: Double Sharing - Tenant Rahul Sharma (PAID)
    final r101 = repo.addRoom(
      propertyId: property.id,
      roomNumber: '101',
      floorNumber: 1,
      sharingType: RoomSharingType.doubleSharing,
      baseRentPerBed: 7500.0,
      subMeterNumber: 'MTR-101',
      initialMeterReading: 1210.0,
    );
    final ob101 = repo.onboardTenant(
      roomId: r101.id,
      bedId: r101.beds[0].id,
      fullName: 'Rahul Sharma',
      phone: '9829012345',
      workplaceOrCollege: 'Allen Career Institute',
      agreedRent: 7500.0,
      securityDeposit: 15000.0,
    );
    final inv101 = repo.generateInvoice(
      leaseId: ob101.lease.id,
      month: DateTime.now().month,
      year: DateTime.now().year,
      electricityCharges: 640.0,
    );
    repo.recordPayment(
      invoiceId: inv101.id,
      amount: 8140.0, // Fully paid
      transactionRef: 'UPI-9048102941',
    );

    // 3. Room 102: Single Bed - Tenant Amit Verma (OVERDUE)
    final r102 = repo.addRoom(
      propertyId: property.id,
      roomNumber: '102',
      floorNumber: 1,
      sharingType: RoomSharingType.single,
      baseRentPerBed: 8500.0,
      subMeterNumber: 'MTR-102',
      initialMeterReading: 850.0,
    );
    final ob102 = repo.onboardTenant(
      roomId: r102.id,
      bedId: r102.beds[0].id,
      fullName: 'Amit Verma',
      phone: '9829098765',
      workplaceOrCollege: 'Resonance Kota',
      agreedRent: 8500.0,
      securityDeposit: 17000.0,
    );
    final inv102 = repo.generateInvoice(
      leaseId: ob102.lease.id,
      month: DateTime.now().month,
      year: DateTime.now().year,
      electricityCharges: 450.0,
    );
    repo.updateInvoiceStatus(inv102.id, InvoiceStatus.overdue);

    // 4. Room 103: Double Sharing - Due Today / Partial Payment
    final r103 = repo.addRoom(
      propertyId: property.id,
      roomNumber: '103',
      floorNumber: 1,
      sharingType: RoomSharingType.doubleSharing,
      baseRentPerBed: 7000.0,
      subMeterNumber: 'MTR-103',
      initialMeterReading: 410.0,
    );
    final ob103 = repo.onboardTenant(
      roomId: r103.id,
      bedId: r103.beds[0].id,
      fullName: 'Vikas Meena',
      phone: '9829055443',
      workplaceOrCollege: 'Motion Education',
      agreedRent: 7000.0,
    );
    final inv103 = repo.generateInvoice(
      leaseId: ob103.lease.id,
      month: DateTime.now().month,
      year: DateTime.now().year,
      electricityCharges: 300.0,
    );
    repo.recordPayment(
      invoiceId: inv103.id,
      amount: 4000.0, // Partial payment
    );

    // 5. Room 104: Double Sharing - VACANT
    repo.addRoom(
      propertyId: property.id,
      roomNumber: '104',
      floorNumber: 1,
      sharingType: RoomSharingType.doubleSharing,
      baseRentPerBed: 7500.0,
      initialMeterReading: 200.0,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rentKhataRepositoryProvider);
    final currentLang = ref.watch(languageProvider);
    final repoNotifier = ref.read(rentKhataRepositoryProvider.notifier);

    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    final totalCollected = repoNotifier.getTotalCollectedRent(currentMonth, currentYear);
    final pendingDues = repoNotifier.getTotalPendingDues(currentMonth, currentYear);
    final occupancy = repoNotifier.getOccupancyStats();

    final property = state.properties.isNotEmpty ? state.properties.first : null;
    final rooms = state.rooms;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ref.tr('appName'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            Text(
              property != null ? '${property.name} (${property.city})' : 'Setup Your PG / Hostel',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher
          TextButton.icon(
            onPressed: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
            icon: const Icon(Icons.language, size: 18, color: AppColors.primary),
            label: Text(
              currentLang == AppLanguage.english ? 'हिंदी / Hinglish' : 'English',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Card (Real-Time Reactive from Repository)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.tr('totalCollected'),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(totalCollected),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusPaid,
                                ),
                              ),
                              Text(
                                '${state.payments.length} Payments Received',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 50, color: AppColors.divider),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.tr('pendingDues'),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(pendingDues),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusOverdue,
                                ),
                              ),
                              Text(
                                '${state.invoices.where((i) => i.balanceDue > 0).length} Invoices Pending',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ref.tr('occupancy'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${occupancy.occupiedBeds} / ${occupancy.totalBeds} Beds (${occupancy.occupancyRate.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Demo Shortcut Button (If database is empty)
            if (rooms.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Quick Test: Pre-load Sample PG Data',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ek click mein 4 rooms (1 Paid, 1 Overdue, 1 Due, 1 Vacant) add karein taaki aap live test kar sakein!',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: '⚡ Pre-load Kota PG Demo (Live Test)',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => _loadSamplePGData(ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section Header: Rooms List & Actions (Add Room + Onboard Tenant)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  '${ref.tr("rooms")} (${rooms.length})',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const AddTenantDialog(),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_rounded, size: 17, color: AppColors.primary),
                      label: const Text('Add Tenant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final propId = property?.id ??
                            repoNotifier.addProperty(
                              name: 'My Hostel',
                              address: 'Main Road',
                              city: 'Kota',
                              stateName: 'Rajasthan',
                              pincode: '324005',
                            ).id;

                        showDialog(
                          context: context,
                          builder: (ctx) => AddRoomDialog(propertyId: propId),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Room Cards List
            if (rooms.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      const Text(
                        'No rooms added yet (अभी कोई कमरा नहीं है)',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rooms.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final room = rooms[i];
                  // Find latest invoice for this room
                  final invoice = state.invoices
                      .where((inv) => inv.roomId == room.id)
                      .toList()
                      .reversed
                      .firstOrNull;

                  return RoomCard(
                    room: room,
                    latestInvoice: invoice,
                    onBedTap: (bed) {
                      if (bed.isOccupied) {
                        // Find tenant and lease
                        final tenant = state.tenants.where((t) => t.id == bed.currentTenantId).firstOrNull;
                        final lease = state.leases.where((l) => l.bedId == bed.id && l.isActive).firstOrNull;
                        if (tenant != null && lease != null) {
                          showDialog(
                            context: context,
                            builder: (dCtx) => TenantProfileDialog(
                              tenant: tenant,
                              lease: lease,
                              roomNumber: room.roomNumber,
                              bedLabel: bed.bedLabel,
                            ),
                          );
                        }
                      } else {
                        // Open onboarding dialog pre-filled with this room and bed
                        showDialog(
                          context: context,
                          builder: (dCtx) => AddTenantDialog(
                            preselectedRoomId: room.id,
                            preselectedBedId: bed.id,
                          ),
                        );
                      }
                    },
                    onAddReading: () {
                      showDialog(
                        context: context,
                        builder: (dCtx) => QuickMeterDialog(room: room),
                      );
                    },
                    onRecordPayment: () {
                      if (invoice == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No active bill for this room')),
                        );
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (dCtx) => QuickPaymentDialog(
                          invoice: invoice,
                          roomNumber: room.roomNumber,
                        ),
                      );
                    },
                    onSendReminder: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'WhatsApp reminder prepared for Room ${room.roomNumber} with UPI payment link!',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
