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

    // Room Status Badges
    'statusPaid': {
      AppLanguage.english: 'Paid',
      AppLanguage.hinglish: 'जमा हो गया (Paid)',
    },
    'statusOverdue': {
      AppLanguage.english: 'Overdue',
      AppLanguage.hinglish: 'बाकी है (Overdue)',
    },
    'statusDueToday': {
      AppLanguage.english: 'Due Today',
      AppLanguage.hinglish: 'आज देना है (Due Today)',
    },
    'statusVacant': {
      AppLanguage.english: 'Vacant',
      AppLanguage.hinglish: 'खाली है (Vacant)',
    },

    // Actions
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
