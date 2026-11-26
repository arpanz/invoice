import 'package:flutter/material.dart';
import '../localization/l10n.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'app_lock_service.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key, required this.service});

  final AppLockService service;

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  String? _error;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _error = null);
    final error = await action();
    if (mounted && error != null) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack),
          tooltip: context.l10n.back,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.appLock),
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.canvas,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(context.l10n.requireAuthentication),
                    subtitle: Text(context.l10n.useYourScreenLockOrBiometrics),
                    value: service.enabled,
                    onChanged: service.busy
                        ? null
                        : (value) => _run(() => service.setEnabled(value, localizations: context.l10n)),
                  ),
                  Divider(height: 1, color: AppColors.hairline),
                  ListTile(
                    title: Text(context.l10n.lockAfter),
                    subtitle: Text(context.l10n.timeSpentAwayFromTheApp),
                    trailing: DropdownButton<AppLockTimeout>(
                      value: service.timeout,
                      icon: const Icon(AppIcons.chevronDown),
                      dropdownColor: AppColors.canvas,
                      underline: const SizedBox.shrink(),
                      onChanged: service.busy || !service.enabled
                          ? null
                          : (value) {
                              if (value != null) {
                                _run(() => service.setTimeout(value, localizations: context.l10n));
                              }
                            },
                      items: [
                        for (final choice in AppLockTimeout.values)
                          DropdownMenuItem(
                            value: choice,
                            child: Text(choice.label(context.l10n)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: TextStyle(color: AppColors.error)),
              ),
          ],
        ),
      ),
    );
  }
}
