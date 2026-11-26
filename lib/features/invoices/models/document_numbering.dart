import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DocumentNumbering {
  static const preferencesKey = 'document_numbering';
  static final _prefixPattern = RegExp(r'^[A-Za-z0-9/-]+$');

  final String invoicePrefix;
  final String estimatePrefix;
  final int digits;
  final int nextInvoice;
  final int nextEstimate;
  final bool addFinancialYear;

  const DocumentNumbering({
    this.invoicePrefix = 'INV',
    this.estimatePrefix = 'EST',
    this.digits = 5,
    this.nextInvoice = 1,
    this.nextEstimate = 1,
    this.addFinancialYear = false,
  });

  static bool validPrefix(String value) => _prefixPattern.hasMatch(value);
  static bool validDigits(int value) => value >= 3 && value <= 8;

  factory DocumentNumbering.read(SharedPreferences prefs) {
    final raw = prefs.getString(preferencesKey);
    if (raw == null) return const DocumentNumbering();
    final Object? data;
    try {
      data = jsonDecode(raw);
    } on FormatException {
      return const DocumentNumbering();
    }
    if (data is! Map<String, dynamic>) return const DocumentNumbering();
    final values = data;

    String prefix(String key, String fallback) {
      final value = values[key];
      return value is String && validPrefix(value) ? value : fallback;
    }

    int start(String key) {
      final value = values[key];
      return value is int && value > 0 ? value : 1;
    }

    final width = data['digits'];
    return DocumentNumbering(
      invoicePrefix: prefix('invoicePrefix', 'INV'),
      estimatePrefix: prefix('estimatePrefix', 'EST'),
      digits: width is int && validDigits(width) ? width : 5,
      nextInvoice: start('nextInvoice'),
      nextEstimate: start('nextEstimate'),
      addFinancialYear: data['addFinancialYear'] == true,
    );
  }

  Future<bool> save(SharedPreferences prefs) => prefs.setString(
    preferencesKey,
    jsonEncode({
      'invoicePrefix': invoicePrefix,
      'estimatePrefix': estimatePrefix,
      'digits': digits,
      'nextInvoice': nextInvoice,
      'nextEstimate': nextEstimate,
      'addFinancialYear': addFinancialYear,
    }),
  );

  String prefix({required bool estimate, required DateTime date}) {
    final base = estimate ? estimatePrefix : invoicePrefix;
    if (!addFinancialYear) return base;
    final year = date.month >= DateTime.april ? date.year : date.year - 1;
    final end = ((year + 1) % 100).toString().padLeft(2, '0');
    return '$base/$year-$end/';
  }
}
