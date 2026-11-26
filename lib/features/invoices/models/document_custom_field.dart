import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DocumentCustomField {
  static const maxFields = 5;

  final String label;
  final String value;

  const DocumentCustomField({required this.label, this.value = ''});

  static String encode(Iterable<DocumentCustomField> fields) => jsonEncode([
    for (final field in fields.take(maxFields))
      {'label': field.label, 'value': field.value},
  ]);

  static List<DocumentCustomField> decode(Object? raw) {
    if (raw is! String) return const [];
    final Object? data;
    try {
      data = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (data is! List) return const [];
    return [
      for (final item in data)
        if (item is Map &&
            item['label'] is String &&
            (item['value'] == null || item['value'] is String))
          DocumentCustomField(
            label: item['label'] as String,
            value: item['value'] as String? ?? '',
          ),
    ].take(maxFields).toList(growable: false);
  }

  static List<DocumentCustomField> forSave(
    Iterable<DocumentCustomField> fields,
  ) => [
    for (final field in fields)
      if (field.label.trim().isNotEmpty)
        DocumentCustomField(
          label: field.label.trim(),
          value: field.value.trim(),
        ),
  ].take(maxFields).toList(growable: false);
}

class DocumentFieldPreferences {
  static const defaultsKey = 'default_invoice_custom_fields';
  static const recentKey = 'recent_document_field_labels';

  static List<DocumentCustomField> defaults(SharedPreferences prefs) => [
    for (final field in DocumentCustomField.decode(prefs.getString(defaultsKey)))
      DocumentCustomField(label: field.label),
  ];

  static List<String> recent(SharedPreferences prefs) =>
      prefs.getStringList(recentKey) ?? const [];

  static Future<void> remember(Iterable<DocumentCustomField> fields) async {
    final labels = fields
        .map((field) => field.label)
        .where((label) => label.isNotEmpty);
    if (labels.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = <String>{};
    final merged = [
      ...labels,
      ...recent(prefs),
    ].where((label) => seen.add(label.toLowerCase())).take(12).toList();
    await prefs.setStringList(recentKey, merged);
  }
}
