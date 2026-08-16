import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/features/settings/widgets/signature_pad_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SignaturePadSheet renders canvas, tools, and actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SignaturePadSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Draw Signature'), findsOneWidget);
    expect(find.text('Sign with your finger or stylus'), findsOneWidget);
    expect(find.text('Draw inside this box'), findsOneWidget);
    expect(find.text('Authorized Signatory'), findsOneWidget);
    expect(find.text('Use Signature'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('SignaturePadSheet allows drawing strokes and shows drawing tools', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SignaturePadSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Drag on drawing canvas
    final canvasFinder = find.byType(CustomPaint).first;
    await tester.drag(canvasFinder, const Offset(60, 40));
    await tester.pumpAndSettle();

    // The 'Draw inside this box' placeholder should disappear once strokes exist
    expect(find.text('Draw inside this box'), findsNothing);

    // Tap clear button to reset
    final clearButton = find.byIcon(Icons.delete_outline_rounded);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Draw inside this box'), findsOneWidget);
  });
}
