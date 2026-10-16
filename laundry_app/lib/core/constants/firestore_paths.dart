/// Names of every Firestore top level collection used by the system. Keeping
/// these in one place avoids typo bugs and makes the security rules easy to
/// cross reference against the actual queries the app performs.
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String providers = 'providers';
  static const String services = 'services';
  static const String orders = 'orders';
  static const String payments = 'payments';
  static const String notifications = 'notifications';
  static const String reviews = 'reviews';
  static const String addresses = 'addresses';
  static const String settings = 'settings';
  static const String ussdSessions = 'ussd_sessions';
}
