import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rent_manager/core/database/rent_khata_repository.dart';
import 'package:rent_manager/features/dashboard/presentation/dashboard_screen.dart';
import 'package:rent_manager/features/expenses/models/expense_model.dart';
import 'package:rent_manager/features/invoice/models/invoice_model.dart';
import 'package:rent_manager/features/meter/domain/electricity_calculator.dart';
import 'package:rent_manager/features/payment/domain/upi_uri_builder.dart';
import 'package:rent_manager/features/payment/models/payment_model.dart';
import 'package:rent_manager/features/receipt/domain/pdf_receipt_generator.dart';
import 'package:rent_manager/features/room/models/room_model.dart';
import 'package:rent_manager/features/whatsapp/domain/whatsapp_message_builder.dart';

void main() {
  group('RentKhata Step 12: End-to-End Golden Path Full Billing Cycle', () {
    late RentKhataRepository repo;

    setUp(() {
      repo = RentKhataRepository();
    });

    test('Complete 10-Step Golden Path: Property -> Onboarding -> Meter -> Invoice -> UPI -> WhatsApp -> Payment -> PDF Receipt -> Expense -> Net Profit', () async {
      // -----------------------------------------------------------------------
      // STEP 1: Property Initialization (Landlord profile & UPI VPA)
      // -----------------------------------------------------------------------
      final property = repo.addProperty(
        name: 'Krishna Residency',
        address: 'Landmark City, Kunadi',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324008',
        defaultElectricityRate: 10.0,
        upiVpa: 'landlord@oksbi',
        upiAccountName: 'Ram Avatar Sharma',
      );

      expect(repo.state.properties.length, 1);
      expect(repo.state.properties.first.name, 'Krishna Residency');
      expect(repo.state.properties.first.upiVpa, 'landlord@oksbi');

      // -----------------------------------------------------------------------
      // STEP 2: Add Room 101 with Initial Sub-Meter Dial at 1000.0 Units
      // -----------------------------------------------------------------------
      final room = repo.addRoom(
        propertyId: property.id,
        roomNumber: '101',
        floorNumber: 1,
        sharingType: RoomSharingType.single,
        baseRentPerBed: 7500.0,
        subMeterNumber: 'MTR-101',
        initialMeterReading: 1000.0,
      );

      expect(repo.state.rooms.length, 1);
      expect(room.hasVacantBed, isTrue);
      expect(room.beds.length, 1);

      // -----------------------------------------------------------------------
      // STEP 3: Tenant Onboarding & Digital KYC (Rahul Sharma)
      // -----------------------------------------------------------------------
      final onboarding = repo.onboardTenant(
        roomId: room.id,
        bedId: room.beds.first.id,
        fullName: 'Rahul Sharma',
        phone: '9829054321',
        workplaceOrCollege: 'Allen Career Institute',
        agreedRent: 7500.0,
        securityDeposit: 7500.0,
      );

      // Room status should now have occupied bed
      final occupiedRoom = repo.state.rooms.firstWhere((r) => r.id == room.id);
      expect(occupiedRoom.isFullyOccupied, isTrue);
      expect(repo.state.tenants.length, 1);
      expect(repo.state.leases.length, 1);

      // -----------------------------------------------------------------------
      // STEP 4: Month-End Electricity Sub-Meter Reading & Mathematical Proof
      // -----------------------------------------------------------------------
      final calculation = ElectricityCalculator.calculate(
        previousReading: 1000.0,
        currentReading: 1080.0,
        ratePerUnit: 10.0,
        activeTenantsCount: 1,
      );

      expect(calculation.unitsConsumed, 80.0);
      expect(calculation.totalRoomAmount, 800.0);
      expect(calculation.perTenantAmount, 800.0);

      final meterProof = calculation.toWhatsAppMathString(roomNumber: '101');
      expect(meterProof, contains('80 Units'));
      expect(meterProof, contains('₹800'));

      final meterReading = repo.recordMeterReading(
        roomId: room.id,
        currentReading: 1080.0,
        ratePerUnit: 10.0,
      );

      expect(repo.state.meterReadings.length, 1);
      expect(meterReading.unitsConsumed, 80.0);
      expect(meterReading.totalAmount, 800.0);

      // Verify room's updated meter reading
      final roomAfterMeter = repo.state.rooms.firstWhere((r) => r.id == room.id);
      expect(roomAfterMeter.currentMeterReading, 1080.0);

      // -----------------------------------------------------------------------
      // STEP 5: Automated Batch Invoice Generation (Rent + Electricity)
      // -----------------------------------------------------------------------
      final invoice = repo.generateInvoice(
        leaseId: onboarding.lease.id,
        month: 4,
        year: 2026,
        electricityCharges: 800.0,
      );

      expect(invoice.baseRent, 7500.0);
      expect(invoice.electricityCharges, 800.0);
      expect(invoice.totalAmount, 8300.0);
      expect(invoice.balanceDue, 8300.0);
      expect(invoice.status, InvoiceStatus.pending);

      // -----------------------------------------------------------------------
      // STEP 6: Dynamic NPCI UPI Deep-Link & WhatsApp Intent Construction
      // -----------------------------------------------------------------------
      final upiUriString = UpiUriBuilder.buildUriString(
        upiId: property.upiVpa!,
        payeeName: property.upiAccountName!,
        amount: invoice.totalAmount,
        transactionNote: 'Rent-Room101-Apr2026',
      );

      expect(upiUriString, startsWith('upi://pay?pa=landlord@oksbi'));
      expect(upiUriString, contains('am=8300.00'));
      expect(upiUriString, contains('cu=INR'));

      final waMessage = WhatsAppMessageBuilder.buildMonthlyRentBill(
        tenant: onboarding.tenant,
        room: roomAfterMeter,
        invoice: invoice,
        meterReading: meterReading,
        propertyName: property.name,
        upiVpa: property.upiVpa,
        upiPayeeName: property.upiAccountName,
        language: WhatsAppLanguage.hinglish,
      );

      expect(waMessage, contains('Namaste *Rahul Sharma* ji!'));
      expect(waMessage, contains('Room *101*'));
      expect(waMessage, contains('Base Rent:* ₹7,500'));
      expect(waMessage, contains('Electricity:* ₹800'));
      expect(waMessage, contains('1000 ➔ 1080 = 80 Units @ ₹10/unit'));
      expect(waMessage, contains('*Total Due Amount:* *₹8,300*'));
      expect(waMessage, contains('upi://pay?pa=landlord@oksbi'));

      final waUri = WhatsAppMessageBuilder.buildWhatsAppUri(
        phoneNumber: onboarding.tenant.phone,
        message: waMessage,
      );
      expect(waUri.toString(), contains('wa.me/919829054321'));

      // -----------------------------------------------------------------------
      // STEP 7: Payment Settlement (Tenant Pays ₹8,300 via UPI)
      // -----------------------------------------------------------------------
      final payment = repo.recordPayment(
        invoiceId: invoice.id,
        amount: 8300.0,
        mode: PaymentMode.upi,
        transactionRef: 'UPI-20260430-99887711',
        paymentDate: DateTime(2026, 4, 30),
      );

      // Verify invoice status flips to Paid with zero balance
      final paidInvoice = repo.state.invoices.firstWhere((i) => i.id == invoice.id);
      expect(paidInvoice.status, InvoiceStatus.paid);
      expect(paidInvoice.amountPaid, 8300.0);
      expect(paidInvoice.balanceDue, 0.0);
      expect(paidInvoice.isFullyPaid, isTrue);

      // -----------------------------------------------------------------------
      // STEP 8: On-Device Vector PDF Rent Receipt Generation (HRA Compliant)
      // -----------------------------------------------------------------------
      final pdfBytes = await PdfReceiptGenerator.generateReceiptPdf(
        property: property,
        room: roomAfterMeter,
        tenant: onboarding.tenant,
        invoice: paidInvoice,
        payment: payment,
        meterReading: meterReading,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(3000));
      // PDF documents start with '%PDF-' magic header bytes
      final pdfHeader = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(pdfHeader, '%PDF-');

      // -----------------------------------------------------------------------
      // STEP 9: Operational Expenses Tracking (Staff Salary + Main Electricity)
      // -----------------------------------------------------------------------
      final expenseMaid = repo.recordExpense(
        propertyId: property.id,
        category: ExpenseCategory.staffSalary,
        title: 'Maid & Cleaning Staff Salary',
        amount: 2000.0,
        expenseDate: DateTime(2026, 4, 25),
        paymentMode: PaymentMode.upi,
      );

      final expenseMainMeter = repo.recordExpense(
        propertyId: property.id,
        category: ExpenseCategory.electricityMain,
        title: 'JVVNL Main Commercial Meter Bill',
        amount: 1500.0,
        expenseDate: DateTime(2026, 4, 28),
        paymentMode: PaymentMode.bankTransfer,
      );

      expect(repo.state.expenses.length, 2);
      expect(expenseMaid.amount, 2000.0);
      expect(expenseMainMeter.amount, 1500.0);

      // -----------------------------------------------------------------------
      // STEP 10: Financial Ledger Reconciliation & Net Monthly Cash Flow
      // -----------------------------------------------------------------------
      final cashFlow = repo.getMonthlyCashFlow(
        month: 4,
        year: 2026,
      );

      expect(cashFlow.month, 4);
      expect(cashFlow.year, 2026);
      expect(cashFlow.totalRevenue, 8300.0); // 100% collected
      expect(cashFlow.totalExpenses, 3500.0); // ₹2000 + ₹1500
      expect(cashFlow.netCashFlow, 4800.0); // ₹8300 - ₹3500 = +₹4800 profit
      expect(cashFlow.isProfitable, isTrue);

      // Check category breakdown
      expect(cashFlow.categoryBreakdown[ExpenseCategory.staffSalary], 2000.0);
      expect(cashFlow.categoryBreakdown[ExpenseCategory.electricityMain], 1500.0);
    });

    testWidgets('Dashboard UI reflects End-to-End state: KPIs, Room 101, and Expense Navigation', (tester) async {
      // 1. Add Property
      final property = repo.addProperty(
        name: 'Krishna Residency',
        address: 'Kunadi, Kota',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324008',
        upiVpa: 'landlord@oksbi',
        upiAccountName: 'Ram Avatar',
      );

      // 2. Add Room 101
      final room = repo.addRoom(
        propertyId: property.id,
        roomNumber: '101',
        floorNumber: 1,
        sharingType: RoomSharingType.single,
        baseRentPerBed: 7500.0,
        initialMeterReading: 1000.0,
      );

      // 3. Onboard Tenant
      final ob = repo.onboardTenant(
        roomId: room.id,
        bedId: room.beds.first.id,
        fullName: 'Rahul Sharma',
        phone: '9829054321',
        workplaceOrCollege: 'Allen Kota',
        agreedRent: 7500.0,
      );

      // 4. Generate Invoice for current month
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;

      final inv = repo.generateInvoice(
        leaseId: ob.lease.id,
        month: currentMonth,
        year: currentYear,
        electricityCharges: 800.0,
      );

      // 5. Pay invoice fully
      repo.recordPayment(
        invoiceId: inv.id,
        amount: 8300.0,
      );

      // 6. Record Expense
      repo.recordExpense(
        propertyId: property.id,
        category: ExpenseCategory.staffSalary,
        title: 'Maid Salary',
        amount: 3500.0,
        expenseDate: DateTime.now(),
      );

      // Pump DashboardScreen inside ProviderScope with repo override
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Property Title
      expect(find.text('Krishna Residency (Kota)'), findsOneWidget);

      // Verify Room 101 Card is displayed
      expect(find.text('Room 101'), findsOneWidget);

      // Verify Pending Dues KPI shows ₹0 (since invoice is paid)
      expect(find.text('₹0'), findsOneWidget);

      // Verify Total Collected shows ₹8,300
      expect(find.text('₹8,300'), findsOneWidget);

      // Tap on Expense tracker icon in AppBar
      final expenseIconButton = find.byTooltip('Expenses & Net Profit');
      expect(expenseIconButton, findsOneWidget);
      await tester.tap(expenseIconButton);
      await tester.pumpAndSettle();

      // Verify Expense Tracker Screen opens
      expect(find.text('Expense & P&L Ledger'), findsOneWidget);
      expect(find.text('₹4,800'), findsOneWidget); // Net Profit ₹8300 - ₹3500 = ₹4,800
      expect(find.text('₹8,300'), findsOneWidget); // Gross Revenue
      expect(find.text('₹3,500'), findsOneWidget); // Total Expenses
      expect(find.text('Maid Salary'), findsOneWidget);
    });
  });
}
