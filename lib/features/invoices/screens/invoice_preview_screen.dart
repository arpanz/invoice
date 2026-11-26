import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/database/db_provider.dart';
import '../../../core/notifications/client_reminder_sheet.dart';
import '../../../core/notifications/reminder_schedule.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../paywall/paywall_screen.dart';
import '../../receipts/receipt_pdf_service.dart';
import '../../receipts/receipt_preview_screen.dart';
import '../models/invoice_customization_config.dart';
import '../models/invoice_model.dart';
import '../models/line_item_model.dart';
import '../models/pdf_theme.dart';
import '../services/invoice_actions.dart';
import '../widgets/payments_sheet.dart';
import '../services/invoice_render_service.dart';
import '../services/pdf_generator_service.dart';
import '../../../core/billing/free_limits.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/catalog_localization.dart';
import '../../../core/localization/l10n.dart';
import '../widgets/invoice_customizer_studio_sheet.dart';
import 'create_invoice_screen.dart';
import '../../../shared_widgets/document_pages.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_animations.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late InvoiceModel _invoice;
  Uint8List? _pdfBytes;
  List<MemoryImage>? _rasterPages;
  bool _isLoading = true;
  bool get _isSent => _invoice.sentAt != null;
  PdfTheme _currentTheme = PdfTheme.defaultTheme;
  InvoiceCustomizationConfig _customConfig =
      InvoiceCustomizationConfig.defaultConfig;
  bool _isBottomPanelCollapsed = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _loadThemeAndRender();
  }

  Future<void> _markSentStatus(bool sent) async {
    final sentAt = await InvoiceActions.setSent(_invoice.id, sent);
    if (mounted) {
      setState(() {
        _invoice = sentAt != null
            ? _invoice.copyWith(sentAt: sentAt)
            : _invoice.copyWith(clearSentAt: true);
      });
    }
  }

  Future<BusinessProfile> _getBusinessProfile() =>
      InvoiceRenderService.profileFor(_invoice);

  Future<void> _loadThemeAndRender() async {
    _customConfig = await InvoiceRenderService.designForInvoice(_invoice.id);
    _currentTheme = _customConfig.toPdfTheme();
    await _generateAndRasterizePdf();
  }

  Future<void> _openThemePicker() async {
    final profile = await _getBusinessProfile();
    final paidOn = await InvoiceRenderService.lastPaymentDate(_invoice);
    if (!mounted) return;
    final updated = await InvoiceCustomizerStudioSheet.show(
      context,
      initialConfig: _customConfig,
      invoice: _invoice,
      businessProfile: profile,
      paidOn: paidOn,
      showSetAsDefault: true,
      title: context.l10n.invoiceDesignStudio,
    );
    if (updated != null && mounted) {
      await InvoiceRenderService.saveDesignForInvoice(_invoice.id, updated);
      if (!mounted) return;
      setState(() {
        _customConfig = updated;
        _currentTheme = updated.toPdfTheme();
      });
      await _generateAndRasterizePdf();
    }
  }

  Future<void> _generateAndRasterizePdf() async {
    setState(() => _isLoading = true);
    try {
      final isPro = context.read<BillingService>().isPro;
      final bytes = await InvoiceRenderService.renderInvoice(
        _invoice,
        isPro: isPro,
        design: _customConfig,
      );

      final images = <MemoryImage>[];
      await for (final page in Printing.raster(bytes, dpi: 220)) {
        final png = await page.toPng();
        images.add(MemoryImage(png));
      }

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _rasterPages = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Render preview failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.couldNotShowThePreviewPleaseTryAgain),
          ),
        );
      }
    }
  }

  Future<void> _refreshInvoiceFromDb() async {
    final rows = await DbProvider.query(
      DbProvider.tableInvoices,
      where: 'id = ?',
      whereArgs: [_invoice.id],
    );
    if (rows.isNotEmpty) {
      final itemRows = await DbProvider.query(
        DbProvider.tableLineItems,
        where: 'invoice_id = ?',
        whereArgs: [_invoice.id],
        orderBy: 'sort_order ASC',
      );
      final items = itemRows.map(LineItemModel.fromMap).toList();
      final updated = InvoiceModel.fromMap(rows.first, items: items);
      setState(() => _invoice = updated);
      await _generateAndRasterizePdf();
    }
  }

  /// Changes the payment state through payments (see InvoiceActions).
  Future<void> _updateStatus(InvoiceStatus target) async {
    final changed = await InvoiceActions.changePaymentStatus(
      context,
      _invoice,
      target,
    );
    if (changed && mounted) await _refreshInvoiceFromDb();
  }

  Future<void> _openPayments() async {
    final changed = await PaymentsSheet.show(context, _invoice);
    if (changed && mounted) await _refreshInvoiceFromDb();
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.changeInvoiceStatus,
                        style: AppTypography.serif(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.invoiceWithNumber(_invoice.invoiceNumber),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(AppIcons.close, color: AppColors.slate400),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusOption(
                InvoiceStatus.unpaid,
                context.l10n.unpaid,
                context.l10n.deletesRecordedPayments,
                AppIcons.pendingActions,
                AppColors.statusUnpaid,
                AppColors.statusUnpaidBg,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                InvoiceStatus.partiallyPaid,
                context.l10n.recordAPayment,
                context.l10n.addADepositOrPartPayment,
                AppIcons.pieChart,
                AppColors.statusPartiallyPaid,
                AppColors.statusPartiallyPaidBg,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                InvoiceStatus.paid,
                context.l10n.paidInFull,
                context.l10n.paymentReceivedSuccessfully,
                AppIcons.checkCircleFilled,
                AppColors.statusPaid,
                AppColors.statusPaidBg,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    InvoiceStatus status,
    String label,
    String subtitle,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    final isSelected = _invoice.status == status;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.pop(context);
        _updateStatus(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                AppIcons.checkCircleFilled,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvoice() async {
    if (_pdfBytes == null) return;
    final updated = await InvoiceActions.share(
      context,
      _invoice,
      pdfBytes: _pdfBytes,
    );
    if (updated != null && mounted) setState(() => _invoice = updated);
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    await InvoiceActions.saveToDevice(context, _invoice, pdfBytes: _pdfBytes);
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async => _pdfBytes!,
      name: 'Invoice_${_invoice.invoiceNumber}',
    );
  }

  Future<void> _editInvoice() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateInvoiceScreen(existingInvoice: _invoice),
      ),
    );
    if (updated == true || mounted) {
      await _refreshInvoiceFromDb();
    }
  }

  Future<void> _openTotalReceipt() async {
    final invoice = _invoice;
    try {
      final payments = await DbProvider.paymentsFor(invoice.id);
      if (!mounted || payments.isEmpty) return;
      ReceiptPreviewScreen.open(context, PaymentReceipt.fromPayments(invoice, payments));
    } catch (e) {
      debugPrint('Could not open receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotOpenTheReceipt)),
        );
      }
    }
  }

  void _showMoreActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.moreActions,
                    style: AppTypography.serif(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(AppIcons.close, color: AppColors.slate400),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildActionTile(
                icon: AppIcons.palette,
                iconColor: AppColors.squirclePurpleIcon,
                bgColor: AppColors.squirclePurple,
                title: context.l10n.changeDesign,
                subtitle:
                    context.l10n.designThemeSummary(context.l10n.catalogLabel(_currentTheme.name)),
                // The template's accent as a swatch; the text stays readable.
                trailing: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _currentTheme.previewPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.hairline),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openThemePicker();
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: AppIcons.copy,
                iconColor: AppColors.squircleCyanIcon,
                bgColor: AppColors.squircleCyan,
                title: context.l10n.duplicateInvoice,
                subtitle: context.l10n.createANewCopyWithSameItems,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _duplicateInvoice();
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: _invoice.status == InvoiceStatus.paid
                    ? AppIcons.pending
                    : AppIcons.checkCircle,
                iconColor: _invoice.status == InvoiceStatus.paid
                    ? AppColors.statusUnpaid
                    : AppColors.statusPaid,
                bgColor: _invoice.status == InvoiceStatus.paid
                    ? AppColors.statusUnpaidBg
                    : AppColors.statusPaidBg,
                title: _invoice.status == InvoiceStatus.paid
                    ? context.l10n.markAsUnpaid
                    : context.l10n.markAsPaid,
                subtitle: _invoice.status == InvoiceStatus.paid
                    ? context.l10n.deletesTheRecordedPayments
                    : context.l10n.recordsAPaymentForTheBalance,
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(
                    _invoice.status == InvoiceStatus.paid
                        ? InvoiceStatus.unpaid
                        : InvoiceStatus.paid,
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: AppIcons.payments,
                iconColor: AppColors.squircleGreenIcon,
                bgColor: AppColors.squircleGreen,
                title: context.l10n.payments,
                subtitle: context.l10n.seeRecordOrDeletePayments,
                onTap: () {
                  Navigator.pop(ctx);
                  _openPayments();
                },
              ),
              if (hasReminderBalance(_invoice)) ...[
                const SizedBox(height: 8),
                _buildActionTile(
                  icon: AppIcons.send,
                  iconColor: AppColors.squircleCyanIcon,
                  bgColor: AppColors.squircleCyan,
                  title: context.l10n.sendReminder,
                  subtitle: context.l10n.editAndShareAPaymentReminderWithYour,
                  onTap: () {
                    Navigator.pop(ctx);
                    ClientReminderSheet.show(context, _invoice);
                  },
                ),
              ],
              if (_invoice.paidAmount > 0) ...[
                const SizedBox(height: 8),
                _buildActionTile(
                  icon: AppIcons.receipt,
                  iconColor: AppColors.squircleGreenIcon,
                  bgColor: AppColors.squircleGreen,
                  title: context.l10n.receipt,
                  subtitle: context.l10n.previewAReceiptForAllRecordedPayments,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openTotalReceipt();
                  },
                ),
              ],
              const SizedBox(height: 8),
              _buildActionTile(
                icon: AppIcons.delete,
                iconColor: AppColors.accentRed,
                bgColor: AppColors.statusOverdueBg,
                title: context.l10n.deleteInvoice,
                subtitle: context.l10n.permanentlyRemoveThisInvoice,
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _confirmDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? AppColors.accentRed.withValues(alpha: 0.2)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? AppColors.accentRed
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _duplicateInvoice() async {
    if (!await FreeLimits.canCreateInvoice(context)) return;
    try {
      final copy = await DbProvider.duplicateInvoice(
        _invoice,
        newInvoiceId: const Uuid().v4(),
        newLineId: () => const Uuid().v4(),
      );
      // The copy keeps this invoice's design.
      await InvoiceRenderService.saveDesignForInvoice(copy.id, _customConfig);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.duplicatedAsDatedTodayAndUnpaid(copy.invoiceNumber),
          ),
        ),
      );
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: copy)),
      );
    } catch (e) {
      debugPrint('Duplicate invoice failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.couldNotDuplicateTheInvoicePleaseTryAgain),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (await InvoiceActions.confirmAndDelete(context, _invoice) && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<BillingService>().isPro;
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(
      _invoice.currency,
    );
    final dueDateFormatted = _invoice.dueDate != null
        ? DateFormat('dd MMM yyyy', context.localeName).format(_invoice.dueDate!)
        : DateFormat('dd MMM yyyy', context.localeName).format(_invoice.invoiceDate);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
        ),
        leading: IconButton(
          icon: Icon(
            AppIcons.chevronBack,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _invoice.invoiceNumber,
          style: AppTypography.serif(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(AppIcons.palette, color: AppColors.ink, size: 20),
            tooltip: context.l10n.design,
            onPressed: _openThemePicker,
          ),
          if (!isPro)
            IconButton(
              icon: Icon(
                AppIcons.premium,
                color: AppColors.proGold,
                size: 20,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // The document, as sheets of paper
          Expanded(
            child: DocumentPagesView(pages: _rasterPages, loading: _isLoading),
          ),

          // Bottom Floating Details & Action Panel
          AnimatedContainer(
            duration: AppAnimations.medium,
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(top: BorderSide(color: AppColors.hairline)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: AnimatedSize(
                duration: AppAnimations.medium,
                curve: AppAnimations.defaultCurve,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collapse / Expand Handle
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _isBottomPanelCollapsed =
                                !_isBottomPanelCollapsed,
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 24,
                          ),
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.hairline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    if (_isBottomPanelCollapsed) ...[
                      // Compact collapsed single-row bar
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.l10n.dueDateAndClient(dueDateFormatted, _invoice.clientName),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(
                                    _invoice.grandTotal,
                                    currencyCode: _invoice.currency,
                                    currencySymbol: currencySymbol,
                                  ),
                                  style: AppTypography.serif(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _sendInvoice,
                            tooltip: context.l10n.sendInvoice,
                            icon: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppIcons.send,
                                color: AppColors.onPrimary,
                                size: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isBottomPanelCollapsed = false);
                            },
                            icon: Icon(
                              AppIcons.chevronUp,
                              color: AppColors.muted,
                            ),
                            tooltip: context.l10n.expandDetails,
                          ),
                        ],
                      ),
                    ] else ...[
                      // Row 1: Due Date + Status Dropdown Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.clientAndDueDate(_invoice.clientName, dueDateFormatted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _showStatusPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _invoice.effectiveStatus ==
                                        InvoiceStatus.paid
                                    ? AppColors.statusPaidBg
                                    : _invoice.effectiveStatus ==
                                          InvoiceStatus.partiallyPaid
                                    ? AppColors.statusPartiallyPaidBg
                                    : _invoice.effectiveStatus ==
                                          InvoiceStatus.overdue
                                    ? AppColors.statusOverdueBg
                                    : AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(
                                  9999,
                                ), // pill
                                border: Border.all(
                                  color:
                                      _invoice.effectiveStatus ==
                                          InvoiceStatus.paid
                                      ? AppColors.statusPaid.withValues(
                                          alpha: 0.2,
                                        )
                                      : _invoice.effectiveStatus ==
                                            InvoiceStatus.partiallyPaid
                                      ? AppColors.statusPartiallyPaid
                                            .withValues(alpha: 0.2)
                                      : _invoice.effectiveStatus ==
                                            InvoiceStatus.overdue
                                      ? AppColors.statusOverdue.withValues(
                                          alpha: 0.2,
                                        )
                                      : AppColors.hairline,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.l10n.catalogLabel(_invoice.effectiveStatus.label),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _invoice.effectiveStatus ==
                                              InvoiceStatus.paid
                                          ? AppColors.statusPaid
                                          : _invoice.effectiveStatus ==
                                                InvoiceStatus.partiallyPaid
                                          ? AppColors.statusPartiallyPaid
                                          : _invoice.effectiveStatus ==
                                                InvoiceStatus.overdue
                                          ? AppColors.statusOverdue
                                          : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    AppIcons.chevronDown,
                                    size: 14,
                                    color:
                                        _invoice.effectiveStatus ==
                                            InvoiceStatus.paid
                                        ? AppColors.statusPaid
                                        : _invoice.effectiveStatus ==
                                              InvoiceStatus.partiallyPaid
                                        ? AppColors.statusPartiallyPaid
                                        : _invoice.effectiveStatus ==
                                              InvoiceStatus.overdue
                                        ? AppColors.statusOverdue
                                        : AppColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Row 2: Grand Total + Sent Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            CurrencyFormatter.format(
                              _invoice.grandTotal,
                              currencyCode: _invoice.currency,
                              currencySymbol: currencySymbol,
                            ),
                            style: AppTypography.serif(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                              letterSpacing: -0.6,
                            ),
                          ),
                          Tooltip(
                            message: _isSent
                                ? context.l10n.tapToMarkAsNotSent
                                : context.l10n.tapToMarkAsSent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9999),
                              onTap: () => _markSentStatus(!_isSent),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _isSent
                                      ? AppColors.statusPaidBg
                                      : AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(
                                    9999,
                                  ), // pill
                                  border: Border.all(color: AppColors.hairline),
                                ),
                                child: Text(
                                  _isSent ? context.l10n.sent : context.l10n.notSent,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _isSent
                                        ? AppColors.statusPaid
                                        : AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_invoice.status == InvoiceStatus.partiallyPaid ||
                          _invoice.paidAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              context.l10n.paidAmountLabel(CurrencyFormatter.format(_invoice.paidAmount, currencyCode: _invoice.currency, currencySymbol: currencySymbol)),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.statusPaid,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.balanceDue(CurrencyFormatter.format(_invoice.balanceDue, currencyCode: _invoice.currency, currencySymbol: currencySymbol)),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _invoice.balanceDue > 0
                                    ? AppColors.statusPartiallyPaid
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Row 4: Primary Send Invoice Button (Cal.com Black CTA)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _sendInvoice,
                          icon: Icon(
                            AppIcons.send,
                            size: 18,
                            color: AppColors.onPrimary,
                          ),
                          label: Text(
                            context.l10n.sendInvoice,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Row 5: Action Icons (Download, Print, Edit, More)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionButton(
                            icon: AppIcons.download,
                            label: context.l10n.download,
                            onTap: _downloadPdf,
                          ),
                          _buildActionButton(
                            icon: AppIcons.print,
                            label: context.l10n.print,
                            onTap: _printPdf,
                          ),
                          _buildActionButton(
                            icon: AppIcons.edit,
                            label: context.l10n.edit,
                            onTap: _editInvoice,
                          ),
                          _buildActionButton(
                            icon: AppIcons.moreHoriz,
                            label: context.l10n.more,
                            onTap: _showMoreActions,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Icon(icon, size: 22, color: AppColors.ink),
              ),
              if (hasBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}
