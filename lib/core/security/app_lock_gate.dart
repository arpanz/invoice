import 'package:flutter/material.dart';
import '../localization/l10n.dart';

import '../../shared_widgets/primary_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_typography.dart';
import 'app_lock_service.dart';

class AppLockGate extends StatelessWidget {
  const AppLockGate({super.key, required this.service, required this.child});

  final AppLockService service;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: service,
    child: child,
    builder: (context, child) => Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: service.covered,
          child: Visibility(
            visible: !service.covered,
            maintainState: true,
            child: child!,
          ),
        ),
        if (service.covered)
          service.locked
              ? _UnlockScreen(service: service)
              : ColoredBox(color: AppColors.background),
      ],
    ),
  );
}

class _UnlockScreen extends StatefulWidget {
  const _UnlockScreen({required this.service});

  final AppLockService service;

  @override
  State<_UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<_UnlockScreen> {
  String? _error;

  Future<void> _unlock() async {
    setState(() => _error = null);
    final error = await widget.service.unlock(localizations: context.l10n);
    if (mounted && error != null) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.background,
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              color: AppColors.canvas,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.pin, size: 34, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.invoiceMakerProIsLocked,
                      textAlign: TextAlign.center,
                      style: AppTypography.serif(
                        fontSize: 24,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.useYourDeviceScreenLockOrBiometricsTo,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: context.l10n.unlock,
                      isLoading: widget.service.busy,
                      onPressed: _unlock,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
