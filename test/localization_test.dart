import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/localization/locale_controller.dart';
import 'package:invoice/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Both ARBs cover the same messages with English descriptions', () {
    Map<String, dynamic> read(String language) =>
        jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
            as Map<String, dynamic>;

    final english = read('en');
    final hindi = read('hi');
    Set<String> messages(Map<String, dynamic> arb) =>
        arb.keys.where((key) => !key.startsWith('@')).toSet();

    expect(messages(hindi), messages(english));
    for (final key in messages(english)) {
      expect(english['@$key']?['description'], isNotEmpty, reason: key);
      expect(hindi[key], isNotEmpty, reason: key);
    }
  });

  test('The language preference restores Hindi, English and system', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'invalid'});
    final controller = LocaleController();
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.language, AppLanguage.system);
    expect(controller.locale, isNull);

    final reloaded = LocaleController();
    addTearDown(reloaded.dispose);
    for (final language in [
      AppLanguage.hi,
      AppLanguage.en,
      AppLanguage.system,
    ]) {
      await controller.setLanguage(language);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), language.name);
      await reloaded.load();
      expect(reloaded.language, language);
      expect(reloaded.locale, language.locale);
    }
  });

  test('Hindi supports singular and plural invoice counts', () async {
    final localizations = await AppLocalizations.delegate.load(
      const Locale('hi'),
    );
    expect(localizations.invoiceCount(1), '1 इनवॉइस');
    expect(localizations.invoiceCount(2), '2 इनवॉइस');
  });
}
