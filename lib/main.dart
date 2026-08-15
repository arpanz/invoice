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
import 'features/invoices/screens/create_invoice_screen.dart';
import 'features/invoices/screens/invoice_history_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/settings/screens/settings_screen.dart';

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
  final _historyKey = GlobalKey<InvoiceHistoryScreenState>();

  List<Widget> get _screens => [
    DashboardScreen(key: _dashboardKey),
    const ClientListScreen(),
    const CreateInvoiceScreen(),
    _HistoryScreen(historyKey: _historyKey),
    const SettingsScreen(),
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 77, 64, 0.08),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Overview',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Clients',
                ),
                _buildCenterActionButton(),
                _buildNavItem(
                  index: 3,
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  label: 'History',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
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
        if (index == 3) _historyKey.currentState?.reload();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.slate400,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionButton() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        if (await CreateInvoiceScreen.canCreateNewInvoice(context)) {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
          if (mounted) {
            _dashboardKey.currentState?.reload();
            _historyKey.currentState?.reload();
          }
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
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
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.statusPaidBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: AppColors.accent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A newer version of Invoice Maker Pro is ready with the latest fixes and improvements.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Available version',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '#${info.availableVersionCode ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onUpdateNow,
                      child: const Text('Update now'),
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

class _HistoryScreen extends StatelessWidget {
  final GlobalKey<InvoiceHistoryScreenState>? historyKey;
  const _HistoryScreen({this.historyKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
      ),
      body: InvoiceHistoryScreen(key: historyKey),
    );
  }
}
