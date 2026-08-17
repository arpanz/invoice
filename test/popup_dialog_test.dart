import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/core/theme/app_typography.dart';
import 'package:invoice/shared_widgets/app_dialog.dart';
import 'package:invoice/shared_widgets/app_popup_menu.dart';

void main() {
  group('AppDialog & Popup Design Tests', () {
    testWidgets('AppDialog renders header badge, title, message, and buttons', (
      tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTypography.lightTheme,
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
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

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
          theme: AppTypography.lightTheme,
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

    testWidgets(
      'AppDialog.showPartialPayment calculates percentages and returns amount',
      (tester) async {
        double? enteredAmount;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTypography.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    enteredAmount = await AppDialog.showPartialPayment(
                      context: context,
                      documentNumber: 'INV00042',
                      grandTotal: 1000.0,
                      currencySymbol: '\$',
                      currentPaidAmount: 0.0,
                    );
                  },
                  child: const Text('Open Payment Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Payment Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Record Payment'), findsOneWidget);
        expect(find.text('INV00042'), findsOneWidget);
        expect(find.text('\$1000.00'), findsOneWidget);

        // Verify quick percentage chips (25%, 50%, 75%, 100%)
        expect(find.text('25%'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('100% (Full)'), findsOneWidget);

        // Tap 75% chip
        await tester.tap(find.text('75%'));
        await tester.pumpAndSettle();

        // Submit payment
        await tester.tap(find.text('Save Payment'));
        await tester.pumpAndSettle();

        expect(enteredAmount, equals(750.0));
      },
    );

    testWidgets('AppPopupMenuItem builds items and dividers cleanly', (
      tester,
    ) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTypography.lightTheme,
          home: Scaffold(
            body: Center(
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (val) => selected = val,
                itemBuilder: (_) => [
                  AppPopupMenuItem.item(
                    value: 'edit',
                    title: 'Edit Item',
                    icon: Icons.edit_outlined,
                  ),
                  AppPopupMenuItem.divider(),
                  AppPopupMenuItem.item(
                    value: 'delete',
                    title: 'Delete Item',
                    icon: Icons.delete_outline_rounded,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit Item'), findsOneWidget);
      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Select edit
      await tester.tap(find.text('Edit Item'));
      await tester.pumpAndSettle();

      expect(selected, equals('edit'));
    });
  });
}
