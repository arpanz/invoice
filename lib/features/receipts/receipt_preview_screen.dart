import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/l10n.dart';

import '../../core/billing/billing_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../shared_widgets/document_pages.dart';
import 'receipt_pdf_service.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  final PaymentReceipt receipt;
  final bool isPro;

  const ReceiptPreviewScreen({
    super.key,
    required this.receipt,
    required this.isPro,
  });

  static void open(BuildContext context, PaymentReceipt receipt) {
    final isPro = context.read<BillingService>().isPro;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptPreviewScreen(receipt: receipt, isPro: isPro),
      ),
    );
  }

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  Uint8List? _bytes;
  List<MemoryImage>? _pages;
  bool _loading = true;

  String get _fileName =>
      widget.receipt.number.replaceAll(RegExp(r'[^\w-]'), '_');

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    try {
      final bytes = await ReceiptPdfService.generate(
        widget.receipt,
        isPro: widget.isPro,
      );
      if (!mounted) return;
      setState(() => _bytes = bytes);
      final pages = <MemoryImage>[];
      await for (final page in Printing.raster(bytes, dpi: 160)) {
        pages.add(MemoryImage(await page.toPng()));
      }
      if (mounted) setState(() => _pages = pages);
    } catch (e) {
      debugPrint('Receipt preview failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share(BuildContext buttonContext, Uint8List bytes) async {
    final l10n = context.l10n;
    try {
      final box = buttonContext.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
          fileNameOverrides: ['$_fileName.pdf'],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      _showError(l10n.couldNotShareTheReceipt);
    }
  }

  Future<void> _print(Uint8List bytes) async {
    final l10n = context.l10n;
    try {
      await Printing.layoutPdf(name: _fileName, onLayout: (_) async => bytes);
    } catch (e) {
      _showError(l10n.couldNotOpenPrinting);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(context.l10n.paymentReceipt),
        actions: [
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: context.l10n.shareReceipt,
              icon: const Icon(AppIcons.share),
              onPressed: bytes == null
                  ? null
                  : () => _share(buttonContext, bytes),
            ),
          ),
          IconButton(
            tooltip: context.l10n.printReceipt,
            icon: const Icon(AppIcons.print),
            onPressed: bytes == null ? null : () => _print(bytes),
          ),
        ],
      ),
      body: DocumentPagesView(
        pages: _pages,
        loading: _loading,
        errorText: context.l10n.couldNotShowTheReceiptPreview,
      ),
    );
  }
}
