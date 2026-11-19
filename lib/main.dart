import 'core/utils/image_store.dart';
import 'core/utils/pdf_script_fonts.dart';
import 'features/invoices/services/invoice_render_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app/app_review_service.dart';
import 'core/app/app_update_service.dart';
import 'core/billing/billing_service.dart';
import 'core/database/db_provider.dart';
import 'core/providers/currency_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/theme_controller.dart';
import 'features/clients/screens/client_list_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/estimates/screens/create_estimate_screen.dart';
import 'features/estimates/screens/estimate_list_screen.dart';
import 'features/invoices/screens/create_invoice_screen.dart';
import 'features/items/screens/item_list_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'shared_widgets/paper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inter and Fraunces are bundled in assets/fonts; never fetch at run time.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Light/dark choice, applied before the first frame.
  final themeController = ThemeController();
  await themeController.load();
  SystemChrome.setSystemUIOverlayStyle(ThemeController.overlayStyle);

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
  await billingService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider<BillingService>.value(value: billingService),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
      ],
      child: const InvoiceMakerProApp(),
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

class InvoiceMakerProApp extends StatelessWidget {
  const InvoiceMakerProApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the theme changes; AppColors already reflects it.
    context.watch<ThemeController?>();
    final overlay = ThemeController.overlayStyle;
    return MaterialApp(
      title: 'Invoice Maker Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTypography.theme,
      // Colours switch instantly, so the theme must not tween.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: child!,
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
      await AppReviewService.instance.registerLaunch();
      if (!mounted) return;
      await _maybePromptForAppUpdate();
    });
  }

  Future<void> _maybePromptForAppUpdate() async {
    final result = await AppUpdateService.instance.checkForUpdate();
    if (!mounted || result.status != AppUpdateAvailability.available) return;

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

          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(switch (updateResult) {
                AppUpdateStartResult.started =>
                  'Update flow started. Follow the system prompt to finish.',
                AppUpdateStartResult.cancelled =>
                  'Update cancelled. You can install it later when prompted again.',
                AppUpdateStartResult.unavailable =>
                  'This update is not ready to install yet.',
                AppUpdateStartResult.unsupported =>
                  'In-app updates are only supported on Android.',
                AppUpdateStartResult.failed =>
                  'The update could not be started. Please try again later.',
              }),
            ),
          );
        },
      ),
    );
  }

  // ---- Search: one bar in the dock, applied to whichever tab is open ----
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  static const _searchHints = ['Search invoices', 'Search estimates', 'Search clients', 'Search items'];

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
        body: IndexedStack(index: _currentIndex, children: _screens),
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
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
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
          _buildNavItem(index: 0, icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Invoices'),
          _buildNavItem(index: 1, icon: Icons.request_quote_outlined, activeIcon: Icons.request_quote_rounded, label: 'Estimates'),
          _buildNavItem(index: 2, icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Clients'),
          _buildNavItem(index: 3, icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Items'),
          Tooltip(
            message: 'Search',
            child: InkResponse(
              onTap: _openSearch,
              radius: 24,
              child: SizedBox(
                width: 42,
                height: 52,
                child: Icon(Icons.search_rounded, color: AppColors.ink, size: 22),
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
          Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
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
            tooltip: 'Close search',
            onPressed: _closeSearch,
            icon: Icon(Icons.close_rounded, color: AppColors.ink, size: 20),
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
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
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
      label: 'Create',
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
            child: Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 28),
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
                  child: Text('Create New Document', style: AppTypography.serif(fontSize: 22, color: AppColors.ink)),
                ),
                const SizedBox(height: 14),
                _CreateOption(
                  primary: true,
                  icon: Icons.receipt_long_rounded,
                  title: 'New Invoice',
                  subtitle: 'Bill a client for work or items',
                  onTap: () => go(_newInvoice),
                ),
                const SizedBox(height: 8),
                _CreateOption(
                  icon: Icons.request_quote_rounded,
                  title: 'New Estimate / Quote',
                  subtitle: 'Send a price before you bill',
                  onTap: () => go(_newEstimate),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _CreateOption(
                        compact: true,
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Client',
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
                        icon: Icons.add_box_outlined,
                        title: 'Item',
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
                        compact ? 'New $title' : title,
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
                if (!compact) Icon(Icons.arrow_forward_rounded, color: fg.withValues(alpha: 0.8), size: 18),
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
                  Icons.system_update_alt_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Update available',
                style: AppTypography.serif(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A newer version of Invoice Maker Pro is ready with the latest fixes and improvements.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 18),
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
                        child: const Text('Later'),
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
                        child: const Text('Update now'),
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
