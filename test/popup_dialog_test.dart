import 'package:invoice/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/theme/app_typography.dart';
import 'package:invoice/shared_widgets/app_dialog.dart';
import 'package:invoice/shared_widgets/app_popup_menu.dart';
import 'package:invoice/core/theme/app_icons.dart';

void main() {
  group('AppDialog & Popup Design Tests', () {
    testWidgets('AppDialog renders header badge, title, message, and buttons', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTypography.theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.showDelete(
                    context: context,
                    title: 'Delete Invoice?',
                    message: 'This action cannot be undone.',
                  );
                },
                child: const Text('Open Delete Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Open Delete Dialog'));
      await tester.pumpAndSettle();

      // Verify title & message
      expect(find.text('Delete Invoice?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(AppIcons.delete), findsOneWidget);

      // Tap Delete to confirm
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('AppDialog.showConvertEstimate renders correctly and cancels', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTypography.theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.showConvertEstimate(
                    context: context,
                    estimateNumber: 'EST00001',
                    clientName: 'Acme Corp',
                  );
                },
                child: const Text('Open Convert Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Convert Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Convert to Invoice?'), findsOneWidget);
      expect(
        find.text(
          'This will generate an active invoice from EST00001 for Acme Corp and mark this estimate as Converted.',
        ),
        findsOneWidget,
      );
      expect(find.text('Convert to Invoice'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('AppPopupMenuItem builds items and dividers cleanly', (
      tester,
    ) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTypography.theme,
          home: Scaffold(
            body: Center(
              child: PopupMenuButton<String>(
                icon: const Icon(AppIcons.moreVert),
                onSelected: (val) => selected = val,
                itemBuilder: (_) => [
                  AppPopupMenuItem.item(
                    value: 'edit',
                    title: 'Edit Item',
                    icon: AppIcons.edit,
                  ),
                  AppPopupMenuItem.divider(),
                  AppPopupMenuItem.item(
                    value: 'delete',
                    title: 'Delete Item',
                    icon: AppIcons.delete,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byIcon(AppIcons.moreVert));
      await tester.pumpAndSettle();

      expect(find.text('Edit Item'), findsOneWidget);
      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.byIcon(AppIcons.edit), findsOneWidget);
      expect(find.byIcon(AppIcons.delete), findsOneWidget);

      // Select edit
      await tester.tap(find.text('Edit Item'));
      await tester.pumpAndSettle();

      expect(selected, equals('edit'));
    });
  });
}
