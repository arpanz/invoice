import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/gen/app_localizations.dart';
import '../localization/locale_controller.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/invoices/models/invoice_model.dart';
import '../database/db_provider.dart';
import 'reminder_schedule.dart';

class ReminderService {
  ReminderService._();

  static final instance = ReminderService._();
  static const _enabledKey = 'payment_reminders_enabled';
  static const _beforeKey = 'payment_reminders_before_due_days';
  static const _overdueKey = 'payment_reminders_overdue_days';
  static const _payloadPrefix = 'payment-reminder:';
  static const _channelId = 'payment_reminders';
  static const _testId = 7; // Reminder slots use the low bits 0–4.
  static NotificationDetails _details(AppLocalizations l10n) => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      l10n.paymentReminders,
      channelDescription: l10n.reminderChannelDescription,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.private,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  final _notifications = FlutterLocalNotificationsPlugin();
  final invoiceToOpen = ValueNotifier<String?>(null);
  Future<void>? _initialization;
  Future<void> _syncQueue = Future.value();

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!isSupported) return;
    try {
      await (_initialization ??= _initialize());
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher_monochrome'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    final launch = await _notifications.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _handleResponse(launch?.notificationResponse);
    }
  }

  void _handleResponse(NotificationResponse? response) {
    final payload = response?.payload;
    if (payload == null || !payload.startsWith(_payloadPrefix)) return;
    final separator = payload.indexOf(':', _payloadPrefix.length);
    if (separator < 0 || separator + 1 == payload.length) return;
    invoiceToOpen.value = payload.substring(separator + 1);
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      beforeDue: BeforeDueReminder.values.firstWhere(
        (choice) => choice.days == prefs.getInt(_beforeKey),
        orElse: () => BeforeDueReminder.oneDay,
      ),
      overdue: OverdueReminder.values.firstWhere(
        (choice) => choice.days == prefs.getInt(_overdueKey),
        orElse: () => OverdueReminder.sevenDays,
      ),
    );
  }

  Future<bool> enable(ReminderSettings settings) async {
    if (!isSupported) return false;
    await initialize();
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    // On Android, the v19 API only requests runtime permission on SDK 33+.
    final granted = android != null
        ? await android.requestNotificationsPermission()
        : await ios?.requestPermissions(alert: true, sound: true);
    if (granted != true) return false;
    await saveSettings(settings.copyWith(enabled: true));
    return true;
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_beforeKey, settings.beforeDue.days);
    await prefs.setInt(_overdueKey, settings.overdue.days);
    await prefs.setBool(_enabledKey, settings.enabled);
    await _enqueueSync();
  }

  Future<AppLocalizations> _loadLocalizations() async {
    final language = await LocaleController.readLanguage();
    final locale = language.locale ?? basicLocaleListResolution(
      WidgetsBinding.instance.platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    );
    return AppLocalizations.delegate.load(locale);
  }

  Future<void> sendTestNotification() async {
    await initialize();
    final l10n = await _loadLocalizations();
    await _updateAndroidChannel(l10n);
    await _notifications.show(
      _testId,
      l10n.paymentReminders,
      l10n.remindersWorking,
      _details(l10n),
    );
  }

  /// Serialize requests so a foreground refresh cannot overwrite a newer sync.
  Future<void> resyncAll() => _enqueueSync().catchError((Object _) {});

  Future<void> _enqueueSync() {
    if (!isSupported) return Future.value();
    final sync = _syncQueue.then((_) => _resync());
    _syncQueue = sync.catchError((Object error) {
      debugPrint('Payment reminder sync failed: $error');
    });
    return sync;
  }

  Future<void> _resync() async {
    await initialize();
    final settings = await loadSettings();
    final l10n = await _loadLocalizations();
    final pending = await _notifications.pendingNotificationRequests();
    final pendingById = {
      for (final request in pending.where(_isReminder)) request.id: request,
    };
    var schedule = <ScheduledReminder>[];
    if (settings.enabled) {
      await _updateAndroidChannel(l10n);
      final zone = await FlutterTimezone.getLocalTimezone();
      // latest_all includes legacy aliases (e.g. Asia/Calcutta). If the
      // device still reports an unknown id, fall back to UTC rather than
      // abandoning the whole sync.
      tz.Location location;
      try {
        location = tz.getLocation(zone.identifier);
      } catch (_) {
        location = tz.UTC;
      }
      final rows = await DbProvider.query(
        DbProvider.tableInvoices,
        where: 'due_date IS NOT NULL',
      );
      final now = tz.TZDateTime.now(location);
      final today = tz.TZDateTime(location, now.year, now.month, now.day);
      schedule =
          computeReminderSchedule(
            rows.map(InvoiceModel.fromMap),
            settings,
            today,
            l10n: l10n,
          ).where((item) {
            // An inexact alarm may still be pending after its scheduled time.
            return item.time.isAfter(now) ||
                _matches(pendingById[item.id], item);
          }).toList();
      // iOS keeps up to 64 pending local notifications.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final otherCount = pending.where((item) => !_isReminder(item)).length;
        schedule = schedule.take((64 - otherCount).clamp(0, 64)).toList();
      }
    }
    final desired = {for (final item in schedule) item.id: item};
    for (final request in pendingById.values) {
      final replacement = desired[request.id];
      if (replacement == null ||
          (!_matches(request, replacement) &&
              !replacement.time.isAfter(DateTime.now()))) {
        await _notifications.cancel(request.id);
      }
    }
    for (final item in schedule) {
      final time = item.time as tz.TZDateTime;
      if (_matches(pendingById[item.id], item) ||
          !time.isAfter(DateTime.now())) {
        continue;
      }
      // Reusing an ID replaces settings, dates and balances in place.
      await _notifications.zonedSchedule(
        item.id,
        l10n.paymentReminders,
        item.text,
        time,
        _details(l10n),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: _payloadFor(item),
      );
    }
  }

  Future<void> _updateAndroidChannel(AppLocalizations l10n) async {
    final android = _notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        l10n.paymentReminders,
        description: l10n.reminderChannelDescription,
      ),
    );
  }

  bool _isReminder(PendingNotificationRequest request) =>
      request.payload?.startsWith(_payloadPrefix) ?? false;

  String _payloadFor(ScheduledReminder item) =>
      '$_payloadPrefix${item.time.millisecondsSinceEpoch}:${item.invoiceId}';

  bool _matches(PendingNotificationRequest? request, ScheduledReminder item) =>
      request?.payload == _payloadFor(item) && request?.body == item.text;
}
