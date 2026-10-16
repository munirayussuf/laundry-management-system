DateTime dateFromJson(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  return DateTime.now();
}

String dateToJson(DateTime value) => value.toUtc().toIso8601String();
