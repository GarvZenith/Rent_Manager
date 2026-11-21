import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rent_manager/core/database/rent_khata_repository.dart';
import 'package:rent_manager/features/room/models/room_model.dart';
import 'package:rent_manager/features/tenant/presentation/add_tenant_dialog.dart';
import 'package:rent_manager/features/tenant/presentation/tenant_profile_dialog.dart';

void main() {
  group('Step 5 Audit: Tenant Onboarding & KYC Tests', () {
    testWidgets('AddTenantDialog renders inputs and onboards tenant into vacant room', (tester) async {
      final repo = RentKhataRepository();
      final property = repo.addProperty(
        name: 'Test PG',
        address: 'Main St',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324005',
      );

      final room = repo.addRoom(
        propertyId: property.id,
        roomNumber: '201',
        sharingType: RoomSharingType.single,
        baseRentPerBed: 8000.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AddTenantDialog(
                preselectedRoomId: room.id,
                preselectedBedId: room.beds[0].id,
              ),
            ),
          ),
        ),
      );

      // Verify Title & Fields are rendered
      expect(find.text('Onboard Tenant (नया किरायेदार)'), findsOneWidget);
      expect(find.text('Tenant Full Name (पूरा नाम)'), findsOneWidget);
      expect(find.text('WhatsApp Mobile Number'), findsOneWidget);

      // Enter Name
      await tester.enterText(find.byType(TextFormField).at(0), 'Siddharth Roy');
      // Enter Phone
      await tester.enterText(find.byType(TextFormField).at(1), '9829011223');
      // Enter College
      await tester.enterText(find.byType(TextFormField).at(2), 'Allen Kota');

      await tester.pump();

      // Tap Complete Onboarding Button
      final submitBtn = find.text('Complete Onboarding (किरायेदार जोड़ें)');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify that tenant was added in repository
      expect(repo.state.tenants.length, 1);
      expect(repo.state.tenants.first.fullName, 'Siddharth Roy');
      expect(repo.state.tenants.first.phone, '9829011223');

      // Verify that room's bed is now occupied
      final updatedRoom = repo.state.rooms.firstWhere((r) => r.id == room.id);
      expect(updatedRoom.beds[0].isOccupied, isTrue);
      expect(updatedRoom.isFullyOccupied, isTrue);
    });

    testWidgets('TenantProfileDialog displays details and handles Move-Out', (tester) async {
      final repo = RentKhataRepository();
      final property = repo.addProperty(
        name: 'Test PG',
        address: 'Main St',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324005',
      );

      final room = repo.addRoom(
        propertyId: property.id,
        roomNumber: '202',
        sharingType: RoomSharingType.single,
        baseRentPerBed: 7500.0,
      );

      final onboarding = repo.onboardTenant(
        roomId: room.id,
        bedId: room.beds[0].id,
        fullName: 'Rohan Gupta',
        phone: '9829044556',
        workplaceOrCollege: 'Resonance',
        agreedRent: 7500.0,
        securityDeposit: 15000.0,
      );

      // Verify bed is occupied before move-out
      expect(repo.state.rooms.first.beds[0].isOccupied, isTrue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TenantProfileDialog(
                tenant: onboarding.tenant,
                lease: onboarding.lease,
                roomNumber: '202',
                bedLabel: 'Single',
              ),
            ),
          ),
        ),
      );

      // Verify Profile Screen shows tenant name & details
      expect(find.text('Rohan Gupta'), findsOneWidget);
      expect(find.text('Room 202 • Single'), findsOneWidget);
      expect(find.text('Resonance'), findsOneWidget);
      expect(find.text('+91 9829044556'), findsOneWidget);

      // Tap Move-Out
      final moveOutBtn = find.text('Settle Move-Out (कमरा खाली करें)');
      expect(moveOutBtn, findsOneWidget);
      await tester.ensureVisible(moveOutBtn);
      await tester.tap(moveOutBtn);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Confirm Move-Out (कमरा खाली करें)'), findsOneWidget);
      await tester.tap(find.text('Confirm Move-Out'));
      await tester.pumpAndSettle();

      // Verify bed is now vacant!
      final roomAfterMoveOut = repo.state.rooms.firstWhere((r) => r.id == room.id);
      expect(roomAfterMoveOut.beds[0].isOccupied, isFalse);
    });
  });
}
