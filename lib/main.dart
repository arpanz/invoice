import 'l10n/gen/app_localizations.dart';
import 'dart:async';

import 'core/utils/demo_seed.dart';
import 'core/utils/image_store.dart';
import 'core/utils/pdf_script_fonts.dart';
import 'features/invoices/services/invoice_render_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/localization/l10n.dart';
import 'core/localization/locale_controller.dart';
import 'core/app/app_review_service.dart';
import 'core/app/app_update_service.dart';
import 'core/billing/billing_service.dart';
import 'core/database/db_provider.dart';
import 'core/notifications/reminder_service.dart';
import 'core/providers/currency_provider.dart';
import 'core/security/app_lock_gate.dart';
import 'core/security/app_lock_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/theme_controller.dart';
import 'features/clients/screens/client_list_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/estimates/screens/create_estimate_screen.dart';
import 'features/estimates/screens/estimate_list_screen.dart';
import 'features/invoices/screens/create_invoice_screen.dart';
import 'features/invoices/screens/invoice_preview_screen.dart';
import 'features/items/screens/item_list_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'shared_widgets/paper.dart';
import 'core/theme/app_icons.dart';
import 'core/theme/app_animations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inter and Fraunces are bundled in assets/fonts; never fetch at run time.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Debug-only screenshot data (--dart-define=DEMO_SEED=true); a no-op
  // otherwise. Runs before anything reads preferences.
  await DemoSeed.run();

  // Light/dark choice, applied before the first frame.
  final themeController = ThemeController();
  await themeController.load();
  SystemChrome.setSystemUIOverlayStyle(ThemeController.overlayStyle);

  final localeController = LocaleController();
  await localeController.load();

  // Initialize database
  await DbProvider.database;

  // Remove legacy screenshot/demo seed data if present.
  await _cleanupLegacyMockData();
  // After the demo cleanup, so demo rows are never stamped.
  await ImageStore.migrateProfileImages();
  await InvoiceRenderService.runOneTimeMigrations();
  // Downloaded PDF fonts (e.g. Devanagari, Tamil) are kept between runs.
  await PdfScriptFonts.useDiskCache();

  // Initialize billing (the single source of Pro entitlement)
  final billingService = BillingService();
  if (DemoSeed.enabled) {
    // The demo's Pro flag must not be revoked by the store's restore.
    await billingService.loadCachedEntitlement();
  } else {
    await billingService.initialize();
  }

  final appLock = await AppLockService.load();
  final reminders = ReminderService.instance;
  localeController.addListener(() => unawaited(reminders.resyncAll()));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider<BillingService>.value(value: billingService),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ChangeNotifierProvider<AppLockService>.value(value: appLock),
      ],
      child: InvoiceMakerProApp(appLock: appLock, reminders: reminders),
    ),
  );
}

/// Removes demo/screenshot seed data left by early builds.
///
/// Runs once per install. Profile fields are cleared only when the whole
/// profile still matches one of the demo profiles, so a real user whose bank
/// happens to be named like a demo value (e.g. "State Bank of India") keeps it.
Future<void> _cleanupLegacyMockData() async {
  const doneKey = 'legacy_mock_cleanup_v2_done';
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(doneKey) ?? false) return;

  final db = await DbProvider.database;

  const demoClientIds = ['demo-client-1', 'demo-client-2', 'demo-client-3'];
  const demoInvoiceIds = [
    'demo-invoice-1',
    'demo-invoice-2',
    'demo-invoice-3',
    'demo-invoice-4',
    'demo-invoice-5',
  ];

  try {
    await db.transaction((txn) async {
      // Real documents may point at a demo client; detach them first so the
      // delete never violates a foreign key.
      for (final table in [
        DbProvider.tableInvoices,
        DbProvider.tableEstimates,
      ]) {
        await txn.update(
          table,
          {'client_id': null},
          where: 'client_id IN (?, ?, ?)',
          whereArgs: demoClientIds,
        );
      }

      await txn.delete(
        DbProvider.tableLineItems,
        where: "id LIKE 'demo-li-%' OR invoice_id IN (?, ?, ?, ?, ?)",
        whereArgs: demoInvoiceIds,
      );

      await txn.delete(
        DbProvider.tableInvoices,
        where: 'id IN (?, ?, ?, ?, ?)',
        whereArgs: demoInvoiceIds,
      );

      await txn.delete(
        DbProvider.tableClients,
        where: 'id IN (?, ?, ?)',
        whereArgs: demoClientIds,
      );
    });
  } catch (e) {
    // Never block startup on a cleanup; it will be retried next launch.
    debugPrint('Legacy demo cleanup failed: $e');
    return;
  }

  // Clear profile fields only when the profile is still one of the demo
  // profiles: the business name must match, and every other field present
  // must match the same demo profile.
  const demoProfiles = <Map<String, String>>[
    {
      'biz_name': 'Northstar Design Studio',
      'biz_address': '245 Market Street, San Francisco, CA 94105',
      'biz_phone': '+1 (415) 555-0139',
      'biz_email': 'accounts@northstardesign.com',
      'biz_bank_name': 'Chase Bank',
      'biz_account': '7894561230',
      'biz_ifsc': '021000021',
    },
    {
      'biz_name': 'Blue Pine Studio',
      'biz_address': '22 Park Street, Kolkata, West Bengal 700016',
      'biz_phone': '+91 98765 43210',
      'biz_email': 'accounts@bluepinestudio.com',
      'biz_bank_name': 'State Bank of India',
      'biz_account': '123456789012',
      'biz_ifsc': 'SBIN0000456',
      'biz_gstin': '19ABCDE1234F1Z5',
    },
  ];

  for (final demo in demoProfiles) {
    if (isDemoProfile(demo, prefs.getString)) {
      for (final key in demo.keys) {
        await prefs.remove(key);
      }
      break;
    }
  }

  await prefs.setBool(doneKey, true);
}

/// True when the stored profile is exactly a demo profile: the business name
/// matches and no stored field differs from the demo's value.
@visibleForTesting
bool isDemoProfile(
  Map<String, String> demo,
  String? Function(String key) read,
) {
  if (read('biz_name') != demo['biz_name']) return false;
  for (final entry in demo.entries) {
    final current = read(entry.key);
    if (current != null && current != entry.value) return false;
  }
  return true;
}

class InvoiceMakerProApp extends StatefulWidget {
  const InvoiceMakerProApp({super.key, this.appLock, this.reminders});

  final AppLockService? appLock;
  final ReminderService? reminders;

  @override
  State<InvoiceMakerProApp> createState() => _InvoiceMakerProAppState();
}

class _InvoiceMakerProAppState extends State<InvoiceMakerProApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  bool _openingReminder = false;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    final state = binding.lifecycleState;
    if (state != null) widget.appLock?.updateLifecycle(state);
    widget.appLock?.addListener(_queueReminderNavigation);
    widget.reminders?.invoiceToOpen.addListener(_queueReminderNavigation);
    unawaited(widget.reminders?.resyncAll());
    _queueReminderNavigation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.appLock?.removeListener(_queueReminderNavigation);
    widget.reminders?.invoiceToOpen.removeListener(_queueReminderNavigation);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.appLock?.updateLifecycle(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.reminders?.resyncAll());
      _queueReminderNavigation();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    unawaited(widget.reminders?.resyncAll());
  }

  @override
  Future<bool> didPopRoute() async => widget.appLock?.covered ?? false;

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) =>
      widget.appLock?.covered ?? false;

  void _queueReminderNavigation() {
    if (widget.reminders?.invoiceToOpen.value == null || _openingReminder) {
      return;
    }
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (mounted) unawaited(_openReminder());
    });
    binding.ensureVisualUpdate();
  }

  bool get _canOpenReminder =>
      mounted &&
      widget.appLock?.covered != true &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  Future<void> _openReminder() async {
    final reminders = widget.reminders!;
    final pending = reminders.invoiceToOpen;
    final id = pending.value;
    final navigator = _navigator.currentState;
    if (!_canOpenReminder ||
        _openingReminder ||
        id == null ||
        navigator == null) {
      return;
    }
    _openingReminder = true;
    try {
      final invoices = await DbProvider.loadInvoices();
      if (!_canOpenReminder || pending.value != id) return;
      pending.value = null;
      for (final invoice in invoices) {
        if (invoice.id == id) {
          unawaited(
            navigator
                .push<bool>(
                  MaterialPageRoute(
                    builder: (_) => InvoicePreviewScreen(invoice: invoice),
                  ),
                )
                .then((_) => reminders.resyncAll()),
          );
          break;
        }
      }
    } catch (error) {
      debugPrint('Could not open invoice from a reminder: $error');
      if (pending.value == id) pending.value = null;
    } finally {
      _openingReminder = false;
      if (_canOpenReminder) _queueReminderNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the theme changes; AppColors already reflects it.
    context.watch<ThemeController?>();
    final overlay = ThemeController.overlayStyle;
    final appLock = widget.appLock;
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'Invoice Maker Pro',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: context.watch<LocaleController?>()?.locale,
      debugShowCheckedModeBanner: false,
      theme: AppTypography.theme,
      // Colours switch instantly, so the theme must not tween.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: appLock == null
            ? child!
            : AppLockGate(service: appLock, child: child!),
      ),
      home: const AppStartup(),
      routes: {'/home': (context) => const MainNavigationShell()},
    );
  }
}

/// Initial screen that handles onboarding state
class AppStartup extends StatelessWidget {
  const AppStartup({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyProvider>(
      builder: (context, currencyProvider, child) {
        // Show loading while checking preferences
        if (currencyProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show onboarding if not completed
        if (!currencyProvider.onboardingComplete) {
          return const OnboardingScreen();
        }

        // Show main app
        return const MainNavigationShell();
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _estimatesKey = GlobalKey<EstimateListScreenState>();
  final _itemsKey = GlobalKey<ItemListScreenState>();
  final _clientsKey = GlobalKey<ClientListScreenState>();

  List<Widget> get _screens => [
    DashboardScreen(key: _dashboardKey),
    EstimateListScreen(key: _estimatesKey),
    ClientListScreen(key: _clientsKey),
    ItemListScreen(key: _itemsKey),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (OnboardingScreen.openCreateInvoiceOnStart) {
        OnboardingScreen.openCreateInvoiceOnStart = false;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
        );
        _dashboardKey.currentState?.reload();
        if (!mounted) return;
      }
      if (DemoSeed.enabled) return;
      await AppReviewService.instance.registerLaunch();
      if (!mounted) return;
      await _maybePromptForAppUpdate();
    });
  }

  Future<void> _maybePromptForAppUpdate() async {
    final result = await AppUpdateService.instance.checkForUpdate();
    if (!mounted) return;
    // An update downloaded earlier only needs a restart.
    if (AppUpdateService.instance.isDownloaded(result.info)) {
      _offerRestartForUpdate();
      return;
    }
    if (result.status != AppUpdateAvailability.available) return;

    final info = result.info!;
    // Ask about the same update at most once every three days.
    final prefs = await SharedPreferences.getInstance();
    final key = 'update_prompt_shown_${info.availableVersionCode ?? 'unknown'}';
    final lastShown = prefs.getInt(key);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastShown != null && now - lastShown < const Duration(days: 3).inMilliseconds) return;
    await prefs.setInt(key, now);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StartupUpdateSheet(
        info: info,
        onUpdateNow: () async {
          Navigator.pop(ctx);
          final updateResult = await AppUpdateService.instance.startUpdate();
          if (!mounted) return;
          if (updateResult == AppUpdateStartResult.downloaded) {
            _offerRestartForUpdate();
            return;
          }

          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(switch (updateResult) {
                AppUpdateStartResult.started || AppUpdateStartResult.downloaded =>
                  context.l10n.updateFlowStartedFollowTheSystemPromptTo,
                AppUpdateStartResult.cancelled =>
                  context.l10n.updateCancelledYouCanInstallItLaterWhen,
                AppUpdateStartResult.unavailable =>
                  context.l10n.thisUpdateIsNotReadyToInstallYet,
                AppUpdateStartResult.unsupported =>
                  context.l10n.inAppUpdatesAreOnlySupportedOnAndroid,
                AppUpdateStartResult.failed =>
                  context.l10n.theUpdateCouldNotBeStartedPleaseTry,
              }),
            ),
          );
        },
      ),
    );
  }

  /// The update is on the device; installing it restarts the app, so the
  /// user picks the moment.
  void _offerRestartForUpdate() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 12),
        persist: false,
        content: Text(context.l10n.updateDownloadedRestartToFinishInstalling),
        action: SnackBarAction(
          label: context.l10n.restart,
          onPressed: () => AppUpdateService.instance.completeDownloadedUpdate(),
        ),
      ),
    );
  }

  // ---- Search: one bar in the dock, applied to whichever tab is open ----
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<String> get _searchHints => [context.l10n.searchInvoices, context.l10n.searchEstimates, context.l10n.searchClients, context.l10n.searchItems];

  void _applySearch(int index, String q) {
    switch (index) {
      case 0:
        _dashboardKey.currentState?.setSearch(q);
      case 1:
        _estimatesKey.currentState?.setSearch(q);
      case 2:
        _clientsKey.currentState?.setSearch(q);
      case 3:
        _itemsKey.currentState?.setSearch(q);
    }
  }

  void _openSearch() {
    Haptics.tap();
    setState(() => _searching = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    _searchCtrl.clear();
    _applySearch(_currentIndex, '');
    _searchFocus.unfocus();
    setState(() => _searching = false);
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;
    Haptics.tap();
    if (_searching) _closeSearch();
    setState(() => _currentIndex = index);
    if (index == 0) _dashboardKey.currentState?.reload();
    if (index == 1) _estimatesKey.currentState?.reload();
    if (index == 2) _clientsKey.currentState?.reload();
    if (index == 3) _itemsKey.currentState?.reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      // Back closes search, then returns to Invoices, before it leaves the app.
      canPop: !_searching && _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_searching) {
          _closeSearch();
        } else if (_currentIndex != 0) {
          _selectTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        // The stack keeps every tab alive; the fade only plays over it.
        body: _TabEntrance(
          index: _currentIndex,
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),
        // The dock rides on top of the keyboard while searching.
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  Expanded(child: _buildDock()),
                  const SizedBox(width: 10),
                  _buildCenterActionButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDock() {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppColors.isDark
            ? null
            : const [BoxShadow(color: Color.fromRGBO(60, 45, 20, 0.10), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: AnimatedSwitcher(
        duration: AppAnimations.fast,
        switchInCurve: AppAnimations.defaultCurve,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(anim), child: child),
        ),
        child: _searching ? _buildSearchField() : _buildTabs(),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      key: const ValueKey('tabs'),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          _buildNavItem(index: 0, icon: AppIcons.receipt, activeIcon: AppIcons.receiptFilled, label: context.l10n.invoices),
          _buildNavItem(index: 1, icon: AppIcons.estimate, activeIcon: AppIcons.estimateFilled, label: context.l10n.estimates),
          _buildNavItem(index: 2, icon: AppIcons.clients, activeIcon: AppIcons.clientsFilled, label: context.l10n.clients),
          _buildNavItem(index: 3, icon: AppIcons.items, activeIcon: AppIcons.itemsFilled, label: context.l10n.items),
          Tooltip(
            message: context.l10n.search,
            child: InkResponse(
              onTap: _openSearch,
              radius: 24,
              child: SizedBox(
                width: 42,
                height: 52,
                child: Icon(AppIcons.search, color: AppColors.ink, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      key: const ValueKey('search'),
      padding: const EdgeInsets.only(left: 18, right: 4),
      child: Row(
        children: [
          Icon(AppIcons.search, color: AppColors.muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => _applySearch(_currentIndex, v),
              style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w500, color: AppColors.ink),
              cursorColor: AppColors.ink,
              decoration: InputDecoration(
                hintText: _searchHints[_currentIndex],
                hintStyle: GoogleFonts.inter(fontSize: 15.5, color: AppColors.mutedSoft),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.closeSearch,
            onPressed: _closeSearch,
            icon: Icon(AppIcons.close, color: AppColors.ink, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        child: GestureDetector(
          onTap: () => _selectTab(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            curve: AppAnimations.defaultCurve,
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceCard : Colors.transparent,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.ink : AppColors.muted, size: 21),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterActionButton() {
    return Semantics(
      button: true,
      label: context.l10n.create,
      child: PressScale(
        pressedScale: 0.9,
        child: GestureDetector(
          onTap: () {
            Haptics.confirm();
            if (_searching) _closeSearch();
            _showCreateChoiceSheet();
          },
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppColors.isDark
                  ? null
                  : const [BoxShadow(color: Color.fromRGBO(60, 45, 20, 0.22), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: Icon(AppIcons.add, color: AppColors.onPrimary, size: 28),
          ),
        ),
      ),
    );
  }

  Future<void> _newInvoice() async {
    if (!await CreateInvoiceScreen.canCreateNewInvoice(context)) return;
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
    if (mounted) {
      _dashboardKey.currentState?.reload();
      _itemsKey.currentState?.reload();
    }
  }

  Future<void> _newEstimate() async {
    if (!await CreateEstimateScreen.canCreateNewEstimate(context)) return;
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEstimateScreen()));
    if (mounted) _estimatesKey.currentState?.reload();
  }

  void _showCreateChoiceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        void go(VoidCallback action) {
          Navigator.pop(ctx);
          action();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.hairline, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(context.l10n.createNewDocument, style: AppTypography.serif(fontSize: 22, color: AppColors.ink)),
                ),
                const SizedBox(height: 14),
                _CreateOption(
                  primary: true,
                  icon: AppIcons.receipt,
                  title: context.l10n.newInvoice,
                  subtitle: context.l10n.billAClientForWorkOrItems,
                  onTap: () => go(_newInvoice),
                ),
                const SizedBox(height: 8),
                _CreateOption(
                  icon: AppIcons.estimate,
                  title: context.l10n.newEstimateQuote,
                  subtitle: context.l10n.sendAPriceBeforeYouBill,
                  onTap: () => go(_newEstimate),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _CreateOption(
                        compact: true,
                        icon: AppIcons.personAdd,
                        title: context.l10n.client,
                        onTap: () => go(() {
                          _selectTab(2);
                          _clientsKey.currentState?.createNew();
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CreateOption(
                        compact: true,
                        icon: AppIcons.addBox,
                        title: context.l10n.item,
                        onTap: () => go(() {
                          _selectTab(3);
                          _itemsKey.currentState?.createNew();
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One choice in the create sheet. The invoice choice is inked, since
/// it is what people make most.
class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool primary;
  final bool compact;

  const _CreateOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.primary = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.onPrimary : AppColors.ink;
    return PressScale(
      child: Material(
        color: primary ? AppColors.primary : AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: primary ? BorderSide.none : BorderSide(color: AppColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 14 : 16),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compact ? context.l10n.newEntity(title) : title,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.inter(fontSize: 12.5, color: primary ? fg.withValues(alpha: 0.72) : AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!compact) Icon(AppIcons.arrowForward, color: fg.withValues(alpha: 0.8), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupUpdateSheet extends StatelessWidget {
  const _StartupUpdateSheet({required this.info, required this.onUpdateNow});

  final AppUpdateInfo info;
  final Future<void> Function() onUpdateNow;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(16), // rounded.xl
            border: Border.all(color: AppColors.hairline),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.10),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppIcons.systemUpdate,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.updateAvailable,
                style: AppTypography.serif(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.aNewerVersionOfInvoiceMakerProIs,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.hairline),
                          shape: const StadiumBorder(),
                          foregroundColor: AppColors.ink,
                        ),
                        child: Text(context.l10n.later),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onUpdateNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(context.l10n.updateNow),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eases the newly chosen tab in: a short fade with a slight rise.
class _TabEntrance extends StatefulWidget {
  final int index;
  final Widget child;

  const _TabEntrance({required this.index, required this.child});

  @override
  State<_TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<_TabEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppAnimations.medium,
    value: 1,
  );
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: AppAnimations.defaultCurve);

  @override
  void didUpdateWidget(_TabEntrance old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && MediaQuery.maybeDisableAnimationsOf(context) != true) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(offset: Offset(0, 10 * (1 - _t.value)), child: child),
      ),
    );
  }
}
