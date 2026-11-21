/// Application-wide constants for RentKhata
class AppConstants {
  static const String appName = 'RentKhata';
  static const String appTagline = 'Hostel & PG Rent Manager';
  static const String appVersion = '1.0.0';

  // Default Business Rules
  static const double defaultElectricityRate = 10.00; // ₹10 per unit (kWh)
  static const int defaultRentDueDay = 1; // 1st of every month
  static const int defaultGracePeriodDays = 4; // Due till 5th

  // Free Tier Limits
  static const int freeTierRoomLimit = 4; // Up to 4 rooms/beds free forever
}
