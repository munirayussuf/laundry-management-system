import 'dart:convert';
import 'package:flutter/widgets.dart';

ImageProvider<Object>? profileImageProvider(String value) {
  if (value.startsWith('data:image/')) {
    try {
      return MemoryImage(base64Decode(value.substring(value.indexOf(',') + 1)));
    } on FormatException {
      return null;
    }
  }
  return value.isEmpty ? null : NetworkImage(value);
}
