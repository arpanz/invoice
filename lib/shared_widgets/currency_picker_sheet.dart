import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/models/currency_model.dart';
import '../core/providers/currency_provider.dart';
import '../core/theme/app_colors.dart';

class CurrencyPickerSheet extends StatefulWidget {
  final Function(Currency)? onCurrencySelected;

  const CurrencyPickerSheet({super.key, this.onCurrencySelected});

  static Future<Currency?> show(BuildContext context,
      {Function(Currency)? onCurrencySelected}) {
    return showModalBottomSheet<Currency>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CurrencyPickerSheet(
        onCurrencySelected: (curr) {
          if (onCurrencySelected != null) {
            onCurrencySelected(curr);
          } else {
            ctx.read<CurrencyProvider>().setCurrency(curr);
            Navigator.pop(ctx, curr);
          }
        },
      ),
    );
  }

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  List<Currency> _filteredCurrencies = SupportedCurrencies.all;
  final TextEditingController _searchCtrl = TextEditingController();

  void _filterCurrencies(String query) {
    setState(() {
      _filteredCurrencies = query.isEmpty
          ? SupportedCurrencies.all
          : SupportedCurrencies.search(query);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = context.watch<CurrencyProvider>().selectedCurrency;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.public_rounded,
                    color: AppColors.ink,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Country & Currency',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Tax system, payment fields & symbol will adapt',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close_rounded, color: AppColors.muted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(8), // rounded.md
                border: Border.all(color: AppColors.hairline),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filterCurrencies,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by country, currency or code...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.mutedSoft,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.muted, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filterCurrencies('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: _filteredCurrencies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == selectedCurrency.code;

                return Material(
                  color: isSelected
                      ? AppColors.surfaceCard
                      : AppColors.canvas,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded.lg
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.hairline,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (widget.onCurrencySelected != null) {
                        widget.onCurrencySelected!(currency);
                      } else {
                        context.read<CurrencyProvider>().setCurrency(currency);
                        Navigator.pop(context, currency);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Text(
                            currency.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currency.countryName.isNotEmpty
                                          ? currency.countryName
                                          : currency.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.surfaceCard,
                                        borderRadius: BorderRadius.circular(9999), // pill
                                      ),
                                      child: Text(
                                        currency.code,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.onPrimary
                                              : AppColors.body,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currency.name} (${currency.symbol}) • ${currency.defaultTax.bankAccountLabel} & ${currency.defaultTax.bankRoutingLabel}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: AppColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            )
                          else
                            Text(
                              currency.symbol,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedSoft,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

