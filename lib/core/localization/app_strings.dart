/// Supported languages for RentKhata
enum AppLanguage {
  english,
  hinglish,
}

/// Bilingual dictionary for Indian PG & hostel landlords
class AppStrings {
  static const Map<String, Map<AppLanguage, String>> _localizedValues = {
    // Navigation & Common
    'appName': {
      AppLanguage.english: 'RentKhata',
      AppLanguage.hinglish: 'RentKhata (रेंट खाता)',
    },
    'dashboard': {
      AppLanguage.english: 'Dashboard',
      AppLanguage.hinglish: 'डैशबोर्ड (Dashboard)',
    },
    'setupProperty': {
      AppLanguage.english: 'Setup Your PG / Hostel',
      AppLanguage.hinglish: 'अपने PG / हॉस्टल का नाम सेट करें',
    },
    'rooms': {
      AppLanguage.english: 'Rooms & Beds',
      AppLanguage.hinglish: 'कमरे और बेड (Rooms & Beds)',
    },
    'tenants': {
      AppLanguage.english: 'Tenants',
      AppLanguage.hinglish: 'किरायेदार (Tenants)',
    },
    'reports': {
      AppLanguage.english: 'Reports & P&L',
      AppLanguage.hinglish: 'हिसाब किताब (Reports)',
    },
    'invoicesLabel': {
      AppLanguage.english: 'Invoices',
      AppLanguage.hinglish: 'Invoices (सभी बिल)',
    },
    'expensesLabel': {
      AppLanguage.english: 'Expenses & P&L',
      AppLanguage.hinglish: 'Expenses & P&L (खर्चे)',
    },
    'allInvoicesTooltip': {
      AppLanguage.english: 'All Invoices',
      AppLanguage.hinglish: 'सभी बिल (All Invoices)',
    },
    'expensesTooltip': {
      AppLanguage.english: 'Expenses & Net Profit',
      AppLanguage.hinglish: 'खर्चे और मुनाफ़ा (Expenses)',
    },

    // Financial Status
    'totalCollected': {
      AppLanguage.english: 'Total Collected',
      AppLanguage.hinglish: 'कुल किराया मिला (Collected)',
    },
    'pendingDues': {
      AppLanguage.english: 'Pending Dues',
      AppLanguage.hinglish: 'बाकी किराया (Pending Dues)',
    },
    'occupancy': {
      AppLanguage.english: 'Occupancy Rate',
      AppLanguage.hinglish: 'भरे हुए कमरे (Occupancy)',
    },
    'paymentsReceived': {
      AppLanguage.english: 'Payments Received',
      AppLanguage.hinglish: 'पेमेंट जमा हुए',
    },
    'invoicesPending': {
      AppLanguage.english: 'Invoices Pending',
      AppLanguage.hinglish: 'बिल बाकी हैं',
    },

    // Onboarding & Empty States
    'welcomeTitle': {
      AppLanguage.english: 'Welcome to RentKhata! 🏠',
      AppLanguage.hinglish: 'RentKhata में आपका स्वागत है! 🏠',
    },
    'welcomeSubtitle': {
      AppLanguage.english: 'Add your first room and onboard tenants digitally.',
      AppLanguage.hinglish: 'अपने PG / Hostel का पहला Room add करें और किरायेदार की डिजिटल एंट्री शुरू करें।',
    },
    'setupFirstProperty': {
      AppLanguage.english: '🏠 Setup First PG / Property',
      AppLanguage.hinglish: '🏠 पहला PG / Property Setup करें',
    },
    'addFirstRoom': {
      AppLanguage.english: '+ Add First Room',
      AppLanguage.hinglish: '+ पहला Room Add करें',
    },
    'noRoomsYet': {
      AppLanguage.english: 'No rooms added yet',
      AppLanguage.hinglish: 'No rooms added yet (अभी कोई कमरा नहीं है)',
    },

    // Room Status Badges
    'statusPaid': {
      AppLanguage.english: 'Paid',
      AppLanguage.hinglish: 'Paid (जमा)',
    },
    'statusOverdue': {
      AppLanguage.english: 'Overdue',
      AppLanguage.hinglish: 'Overdue (बाकी)',
    },
    'statusDueToday': {
      AppLanguage.english: 'Due',
      AppLanguage.hinglish: 'Due (देना है)',
    },
    'statusVacant': {
      AppLanguage.english: 'Vacant',
      AppLanguage.hinglish: 'Vacant (खाली)',
    },

    // Actions
    'addRoom': {
      AppLanguage.english: 'Add Room',
      AppLanguage.hinglish: '+ कमरा जोड़ें (Add Room)',
    },
    'addTenantShort': {
      AppLanguage.english: 'Add Tenant',
      AppLanguage.hinglish: 'किरायेदार जोड़ें (Add Tenant)',
    },
    'meterBtn': {
      AppLanguage.english: 'Meter',
      AppLanguage.hinglish: 'मीटर (Meter)',
    },
    'settleBtn': {
      AppLanguage.english: 'Settle',
      AppLanguage.hinglish: 'जमा (Settle)',
    },
    'remindBtn': {
      AppLanguage.english: 'Remind',
      AppLanguage.hinglish: 'याद दिलाएं (Remind)',
    },
    'tenantActive': {
      AppLanguage.english: 'Tenant Active',
      AppLanguage.hinglish: 'किरायेदार एक्टिव',
    },
    'bedAddTenant': {
      AppLanguage.english: '+ Add Tenant',
      AppLanguage.hinglish: '+ किरायेदार जोड़ें',
    },
    'addReading': {
      AppLanguage.english: 'Add Meter Reading',
      AppLanguage.hinglish: 'मीटर रीडिंग दर्ज करें',
    },
    'sendReminders': {
      AppLanguage.english: 'Send All WhatsApp Reminders',
      AppLanguage.hinglish: 'सभी को व्हाट्सएप पर बिल भेजें',
    },
    'markAsPaid': {
      AppLanguage.english: 'Mark as Paid',
      AppLanguage.hinglish: 'पेमेंट जमा करें (Mark Paid)',
    },
    'viewReceipt': {
      AppLanguage.english: 'View Receipt',
      AppLanguage.hinglish: 'रसीद देखें (View Receipt)',
    },
    'addTenant': {
      AppLanguage.english: 'Add New Tenant',
      AppLanguage.hinglish: 'नया किरायेदार जोड़ें',
    },
  };

  /// Get localized text for a key
  static String get(String key, AppLanguage lang) {
    if (_localizedValues.containsKey(key)) {
      return _localizedValues[key]![lang] ?? _localizedValues[key]![AppLanguage.english]!;
    }
    return key;
  }
}
