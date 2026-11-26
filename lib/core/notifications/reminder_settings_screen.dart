import 'package:flutter/material.dart';
import '../localization/l10n.dart';

import '../../shared_widgets/primary_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'reminder_schedule.dart';
import 'reminder_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final _service = ReminderService.instance;
  ReminderSettings? _settings;
  bool _busy = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _service.loadSettings();
      if (mounted) setState(() => _settings = settings);
    } catch (_) {
      if (mounted) {
        setState(() => _feedback = context.l10n.couldNotLoadReminderSettings);
      }
    }
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _feedback = null;
    });
    final l10n = context.l10n;
    String? feedback;
    var settings = _settings;
    try {
      feedback = await action();
    } catch (error) {
      debugPrint('Payment reminder settings failed: $error');
      feedback = l10n.couldNotUpdatePaymentRemindersPleaseTryAgain;
    } finally {
      try {
        settings = await _service.loadSettings();
      } catch (_) {
        feedback ??= l10n.couldNotLoadReminderSettings;
      }
      if (mounted) {
        setState(() {
          _settings = settings;
          _feedback = feedback;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = _settings;
    final available = _service.isSupported;
    final canEdit = available && !_busy;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack),
          tooltip: context.l10n.back,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.paymentReminders),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!available)
            Text(context.l10n.paymentRemindersAreAvailableOnAndroidAndIos),
          if (settings == null && _feedback == null)
            const Center(child: CircularProgressIndicator()),
          if (settings != null) ...[
            Card(
              color: AppColors.canvas,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(context.l10n.enableReminders),
                    subtitle: Text(context.l10n.notifyMeAboutUnpaidBalances),
                    value: settings.enabled,
                    onChanged: !canEdit
                        ? null
                        : (enabled) => _run(() async {
                            if (enabled) {
                              if (!await _service.enable(settings)) {
                                return l10n.allowNotificationsInYourDeviceSettingsToTurn;
                              }
                            } else {
                              await _service.saveSettings(
                                settings.copyWith(enabled: false),
                              );
                            }
                            return null;
                          }),
                  ),
                  Divider(height: 1, color: AppColors.hairline),
                  _choice<BeforeDueReminder>(
                    context.l10n.beforeTheDueDate,
                    settings.beforeDue,
                    BeforeDueReminder.values,
                    (choice) => _days(choice.days),
                    canEdit
                        ? (choice) => _run(() async {
                            await _service.saveSettings(
                              settings.copyWith(beforeDue: choice),
                            );
                            return null;
                          })
                        : null,
                  ),
                  Divider(height: 1, color: AppColors.hairline),
                  _choice<OverdueReminder>(
                    context.l10n.whenOverdue,
                    settings.overdue,
                    OverdueReminder.values,
                    (choice) => choice.days == 0
                        ? context.l10n.off
                        : l10n.everyDays(choice.days),
                    canEdit
                        ? (choice) => _run(() async {
                            await _service.saveSettings(
                              settings.copyWith(overdue: choice),
                            );
                            return null;
                          })
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.remindersAreScheduledFor9AmOnThe,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: context.l10n.sendTestNotification,
              isLoading: _busy,
              onPressed: canEdit && settings.enabled
                  ? () => _run(() async {
                      await _service.sendTestNotification();
                      return l10n.testNotificationSent;
                    })
                  : null,
            ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(_feedback!, style: TextStyle(color: AppColors.ink)),
          ],
        ],
      ),
    );
  }

  String _days(int count) => switch (count) {
    0 => context.l10n.off,
    1 => context.l10n.daysCount(1),
    _ => context.l10n.daysCount(count),
  };

  Widget _choice<T>(
    String title,
    T value,
    List<T> choices,
    String Function(T) label,
    ValueChanged<T>? change,
  ) => ListTile(
    title: Text(title),
    trailing: DropdownButton<T>(
      value: value,
      icon: const Icon(AppIcons.chevronDown),
      dropdownColor: AppColors.canvas,
      underline: const SizedBox.shrink(),
      items: [
        for (final choice in choices)
          DropdownMenuItem(value: choice, child: Text(label(choice))),
      ],
      onChanged: change == null
          ? null
          : (choice) {
              if (choice != null) change(choice);
            },
    ),
  );
}
