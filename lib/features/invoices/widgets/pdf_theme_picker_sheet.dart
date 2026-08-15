import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../models/pdf_theme.dart';

class PdfThemePickerSheet extends StatefulWidget {
  final PdfTheme currentTheme;
  final Function(PdfTheme theme, bool setAsDefault) onThemeSelected;
  final bool showSetAsDefault;

  const PdfThemePickerSheet({
    super.key,
    required this.currentTheme,
    required this.onThemeSelected,
    this.showSetAsDefault = true,
  });

  static Future<PdfTheme?> show(
    BuildContext context, {
    required PdfTheme currentTheme,
    bool showSetAsDefault = true,
  }) async {
    return showModalBottomSheet<PdfTheme>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PdfThemePickerSheet(
        currentTheme: currentTheme,
        showSetAsDefault: showSetAsDefault,
        onThemeSelected: (selectedTheme, setAsDefault) async {
          if (setAsDefault) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('default_pdf_theme', selectedTheme.id.value);
          }
          if (ctx.mounted) {
            Navigator.pop(ctx, selectedTheme);
          }
        },
      ),
    );
  }

  @override
  State<PdfThemePickerSheet> createState() => _PdfThemePickerSheetState();
}

class _PdfThemePickerSheetState extends State<PdfThemePickerSheet> {
  late PdfTheme _selectedTheme;
  bool _setAsDefault = false;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF Invoice Themes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Select a clean, professional PDF template',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.cardBorder),

            // Theme options list
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                shrinkWrap: true,
                itemCount: PdfTheme.all.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final theme = PdfTheme.all[index];
                  final isSelected = _selectedTheme.id == theme.id;

                  return _buildThemeCard(theme, isSelected);
                },
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            // Footer actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showSetAsDefault) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _setAsDefault = !_setAsDefault;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _setAsDefault,
                              onChanged: (val) {
                                setState(() {
                                  _setAsDefault = val ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Set as default theme for future invoices',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onThemeSelected(_selectedTheme, _setAsDefault);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Theme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(PdfTheme theme, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? theme.previewBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.previewPrimary : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.previewPrimary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.02),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Miniature theme preview box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.previewBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.previewPrimary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mini top bar
                  Container(
                    width: 34,
                    height: 7,
                    decoration: BoxDecoration(
                      color: theme.previewPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Mini line 1
                  Container(
                    width: 26,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.previewSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Mini line 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.previewSecondary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 8,
                        height: 3,
                        decoration: BoxDecoration(
                          color: theme.previewAccent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Title & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        theme.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? theme.previewPrimary : AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.previewPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.previewPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    theme.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Radio selection check
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.previewPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? theme.previewPrimary : AppColors.slate300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
