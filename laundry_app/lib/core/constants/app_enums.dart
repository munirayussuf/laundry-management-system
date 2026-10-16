/// User role. Determines which shell of the application (customer, provider
/// or admin) a signed in user is routed into, and which Firestore security
/// rules apply to them.
enum UserRole { customer, provider, admin }

extension UserRoleX on UserRole {
  String get value => name;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'provider':
        return UserRole.provider;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }
}

/// Formal Laundry providers run a registered business, typically with
/// machines. Mama Fua / Jua Kali providers are informal, independent
/// operators, often washing by hand. Both are first class citizens of the
/// provider database.
enum ProviderType { formalLaundry, mamaFua }

extension ProviderTypeX on ProviderType {
  String get label {
    switch (this) {
      case ProviderType.formalLaundry:
        return 'Formal Laundry';
      case ProviderType.mamaFua:
        return 'Mama Fua / Jua Kali';
    }
  }

  String get value => name;

  static ProviderType fromString(String? value) {
    return value == 'mamaFua' ? ProviderType.mamaFua : ProviderType.formalLaundry;
  }
}

enum WashingMethod { machineWashing, manualHandWashing }

extension WashingMethodX on WashingMethod {
  String get label {
    switch (this) {
      case WashingMethod.machineWashing:
        return 'Machine Washing';
      case WashingMethod.manualHandWashing:
        return 'Manual Hand Washing';
    }
  }

  String get value => name;

  static WashingMethod fromString(String? value) {
    return value == 'manualHandWashing'
        ? WashingMethod.manualHandWashing
        : WashingMethod.machineWashing;
  }
}

enum IroningMethod { electricIron, traditionalCharcoalIron }

extension IroningMethodX on IroningMethod {
  String get label {
    switch (this) {
      case IroningMethod.electricIron:
        return 'Electric Iron';
      case IroningMethod.traditionalCharcoalIron:
        return 'Traditional Charcoal Iron';
    }
  }

  String get value => name;

  static IroningMethod fromString(String? value) {
    return value == 'traditionalCharcoalIron'
        ? IroningMethod.traditionalCharcoalIron
        : IroningMethod.electricIron;
  }
}

/// Full order lifecycle. Providers move an order forward; customers observe
/// it through a live Firestore stream.
enum OrderStatus {
  pending,
  accepted,
  scheduled,
  pickedUp,
  washing,
  ironing,
  ready,
  outForDelivery,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.scheduled:
        return 'Scheduled';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.washing:
        return 'Washing';
      case OrderStatus.ironing:
        return 'Ironing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out For Delivery';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value => name;

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// The statuses a provider is allowed to move an order through in order.
  static List<OrderStatus> get lifecycle => const [
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.scheduled,
        OrderStatus.pickedUp,
        OrderStatus.washing,
        OrderStatus.ironing,
        OrderStatus.ready,
        OrderStatus.outForDelivery,
        OrderStatus.completed,
      ];
}

enum PaymentMethod { mobileMoney, cashOnDelivery }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.cashOnDelivery:
        return 'Cash On Delivery';
    }
  }

  String get value => name;

  static PaymentMethod fromString(String? value) {
    return value == 'cashOnDelivery'
        ? PaymentMethod.cashOnDelivery
        : PaymentMethod.mobileMoney;
  }
}

enum PaymentStatus { pending, paid, failed, cancelled }

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value => name;

  static PaymentStatus fromString(String? value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }
}
