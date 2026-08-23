import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/ads/ad_manager.dart';
import 'core/app/app_review_service.dart';
import 'core/app/app_update_service.dart';
import 'core/billing/billing_service.dart';
import 'core/database/db_provider.dart';
import 'core/providers/currency_provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'features/clients/screens/client_list_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/estimates/screens/create_estimate_screen.dart';
import 'features/estimates/screens/estimate_list_screen.dart';
import 'features/invoices/screens/create_invoice_screen.dart';
import 'features/items/screens/item_list_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize database
  await DbProvider.database;

  // Remove legacy screenshot/demo seed data if present.
  await _cleanupLegacyMockData();

  // Initialize ads and billing
  await AdManager.instance.initialize();

  final billingService = BillingService();
  await billingService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider<BillingService>.value(value: billingService),
      ],
      child: const InvoiceMakerProApp(),
    ),
  );
}

Future<void> _cleanupLegacyMockData() async {
  final db = await DbProvider.database;

  const demoClientIds = ['demo-client-1', 'demo-client-2', 'demo-client-3'];
  const demoInvoiceIds = [
    'demo-invoice-1',
    'demo-invoice-2',
    'demo-invoice-3',
    'demo-invoice-4',
    'demo-invoice-5',
  ];

  await db.transaction((txn) async {
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

  // Only clear profile fields if they still match known mock values.
  final prefs = await SharedPreferences.getInstance();
  const mockValuesByKey = {
    'biz_name': ['Northstar Design Studio', 'Blue Pine Studio'],
    'biz_address': [
      '245 Market Street, San Francisco, CA 94105',
      '22 Park Street, Kolkata, West Bengal 700016',
    ],
    'biz_phone': ['+1 (415) 555-0139', '+91 98765 43210'],
    'biz_email': [
      'accounts@northstardesign.com',
      'accounts@bluepinestudio.com',
    ],
    'biz_bank_name': ['Chase Bank', 'State Bank of India'],
    'biz_account': ['7894561230', '123456789012'],
    'biz_ifsc': ['021000021', 'SBIN0000456'],
  };

  for (final entry in mockValuesByKey.entries) {
    final current = prefs.getString(entry.key);
    if (current != null && entry.value.contains(current)) {
      await prefs.remove(entry.key);
    }
  }

  final gstin = prefs.getString('biz_gstin');
  if (gstin == '19ABCDE1234F1Z5') {
    await prefs.remove('biz_gstin');
  }
}

class InvoiceMakerProApp extends StatelessWidget {
  const InvoiceMakerProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Maker Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTypography.lightTheme,
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
          return const Scaffold(
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

  List<Widget> get _screens => [
    DashboardScreen(key: _dashboardKey),
    EstimateListScreen(key: _estimatesKey),
    const ClientListScreen(),
    ItemListScreen(key: _itemsKey),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppReviewService.instance.registerLaunch();
      if (!mounted) return;
      await _maybePromptForAppUpdate();
    });
  }

  Future<void> _maybePromptForAppUpdate() async {
    final result = await AppUpdateService.instance.checkForUpdate();
    if (!mounted || result.status != AppUpdateAvailability.available) return;

    final info = result.info!;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(9999), // Cal.com nav-pill-group
              border: Border.all(color: AppColors.hairline, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.06),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Invoices',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.request_quote_outlined,
                  activeIcon: Icons.request_quote_rounded,
                  label: 'Estimates',
                ),
                _buildCenterActionButton(),
                _buildNavItem(
                  index: 2,
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Clients',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Items',
                ),
              ],
            ),
          ),
        ),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
        if (index == 0) _dashboardKey.currentState?.reload();
        if (index == 1) _estimatesKey.currentState?.reload();
        if (index == 3) _itemsKey.currentState?.reload();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(9999), // pill-in-pill
          border: isSelected
              ? Border.all(color: AppColors.hairline, width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.ink : AppColors.muted,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.ink : AppColors.muted,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showCreateChoiceSheet();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.primary, // signature Cal.com black
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.18),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  void _showCreateChoiceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create New Document',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Option 1: New Invoice
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (await CreateInvoiceScreen.canCreateNewInvoice(context)) {
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateInvoiceScreen(),
                      ),
                    );
                    if (mounted) {
                      _dashboardKey.currentState?.reload();
                      _itemsKey.currentState?.reload();
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Invoice',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Bill a client for completed services or items',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: New Estimate
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (await CreateEstimateScreen.canCreateNewEstimate(
                    context,
                  )) {
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateEstimateScreen(),
                      ),
                    );
                    if (mounted) {
                      _estimatesKey.currentState?.reload();
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.request_quote_rounded,
                          color: AppColors.ink,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Estimate / Quote',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Send a pricing quote or proposal before billing',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: AppColors.ink,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Update available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A newer version of Invoice Maker Pro is ready with the latest fixes and improvements.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Available version',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${info.availableVersionCode ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
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
                          side: const BorderSide(color: AppColors.hairline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

