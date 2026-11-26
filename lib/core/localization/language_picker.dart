import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'l10n.dart';
import 'locale_controller.dart';

String languageLabel(BuildContext context, AppLanguage language) =>
    switch (language) {
      AppLanguage.system => context.l10n.systemDefault,
      AppLanguage.en => context.l10n.english,
      AppLanguage.hi => context.l10n.hindi,
    };

Future<void> showLanguagePicker(BuildContext context) async {
  final controller = context.read<LocaleController>();
  final selection = await showModalBottomSheet<AppLanguage>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: RadioGroup<AppLanguage>(
        groupValue: controller.language,
        onChanged: (language) => Navigator.pop(context, language),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                context.l10n.language,
                style: AppTypography.serif(fontSize: 18, color: AppColors.ink),
              ),
            ),
            for (final language in AppLanguage.values)
              RadioListTile<AppLanguage>(
                value: language,
                title: Text(languageLabel(context, language)),
                activeColor: AppColors.ink,
              ),
          ],
        ),
      ),
    ),
  );
  if (selection != null) await controller.setLanguage(selection);
}
