import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/l10n.dart';

import '../../../core/database/db_provider.dart';
import '../../../shared_widgets/primary_button.dart';
import '../../invoices/models/document_custom_field.dart';
import '../../invoices/models/document_numbering.dart';
import '../../invoices/widgets/custom_fields_card.dart';

class DocumentSettingsScreen extends StatefulWidget {
  const DocumentSettingsScreen({super.key});

  @override
  State<DocumentSettingsScreen> createState() => _DocumentSettingsScreenState();
}

class _DocumentSettingsScreenState extends State<DocumentSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _invoicePrefix = TextEditingController();
  final _estimatePrefix = TextEditingController();
  final _digits = TextEditingController();
  final _nextInvoice = TextEditingController();
  final _nextEstimate = TextEditingController();
  late final Future<SharedPreferences> _preferences;
  Future<List<String>>? _preview;
  List<DocumentCustomField> _defaults = const [];
  bool _financialYear = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _preferences = _load();
  }

  Future<SharedPreferences> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return prefs;
    final settings = DocumentNumbering.read(prefs);
    _invoicePrefix.text = settings.invoicePrefix;
    _estimatePrefix.text = settings.estimatePrefix;
    _digits.text = settings.digits.toString();
    _nextInvoice.text = settings.nextInvoice.toString();
    _nextEstimate.text = settings.nextEstimate.toString();
    _financialYear = settings.addFinancialYear;
    _defaults = DocumentFieldPreferences.defaults(prefs);
    _updatePreview();
    return prefs;
  }

  @override
  void dispose() {
    for (final controller in [
      _invoicePrefix,
      _estimatePrefix,
      _digits,
      _nextInvoice,
      _nextEstimate,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _checkPrefix(String? value) =>
      DocumentNumbering.validPrefix(value?.trim() ?? '')
      ? null
      : context.l10n.useLettersDigitsHyphensOrSlashes;

  String? _checkDigits(String? value) =>
      DocumentNumbering.validDigits(int.tryParse(value?.trim() ?? '') ?? 0)
      ? null
      : context.l10n.enterANumberFrom3To8;

  int? _start(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 1 : int.tryParse(text, radix: 10);
  }

  String? _checkStart(String? value) =>
      (_start(value) ?? 0) > 0 ? null : context.l10n.enterAPositiveWholeNumber;

  DocumentNumbering? get _settings {
    if (_checkPrefix(_invoicePrefix.text) != null ||
        _checkPrefix(_estimatePrefix.text) != null ||
        _checkDigits(_digits.text) != null ||
        _checkStart(_nextInvoice.text) != null ||
        _checkStart(_nextEstimate.text) != null) {
      return null;
    }
    return DocumentNumbering(
      invoicePrefix: _invoicePrefix.text.trim(),
      estimatePrefix: _estimatePrefix.text.trim(),
      digits: int.parse(_digits.text.trim()),
      nextInvoice: _start(_nextInvoice.text)!,
      nextEstimate: _start(_nextEstimate.text)!,
      addFinancialYear: _financialYear,
    );
  }

  void _updatePreview() {
    final settings = _settings;
    setState(() {
      _preview = settings == null
          ? null
          : Future.wait([
              DbProvider.getNextInvoiceNumber(numbering: settings),
              DbProvider.getNextEstimateNumber(numbering: settings),
            ]);
      // The widget listens on the next frame. Handle errors that complete
      // before then, including results superseded by further typing.
      _preview?.ignore();
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final settings = _settings!;
    final defaults = DocumentCustomField.encode(
      DocumentCustomField.forSave(_defaults),
    );
    setState(() => _saving = true);
    try {
      final prefs = await _preferences;
      final saved = await settings.save(prefs);
      final savedDefaults = await prefs.setString(
        DocumentFieldPreferences.defaultsKey,
        defaults,
      );
      if (!saved || !savedDefaults) {
        throw StateError('Could not save document settings');
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.couldNotSaveDocumentSettingsPleaseTryAgain),
        ),
      );
    }
  }

  Widget _input(
    String label,
    TextEditingController controller,
    FormFieldValidator<String> validator, {
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(labelText: label),
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      autocorrect: false,
      validator: validator,
      onChanged: (_) => _updatePreview(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.documentNumbering)),
      body: SafeArea(
        child: FutureBuilder<SharedPreferences>(
          future: _preferences,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(context.l10n.couldNotLoadDocumentSettings),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _input(context.l10n.invoicePrefix, _invoicePrefix, _checkPrefix),
                  _input(context.l10n.estimatePrefix, _estimatePrefix, _checkPrefix),
                  _input(
                    context.l10n.numberOfDigits,
                    _digits,
                    _checkDigits,
                    numeric: true,
                  ),
                  _input(
                    context.l10n.startInvoiceNumbersFrom,
                    _nextInvoice,
                    _checkStart,
                    numeric: true,
                  ),
                  _input(
                    context.l10n.startEstimateNumbersFrom,
                    _nextEstimate,
                    _checkStart,
                    numeric: true,
                  ),
                  Text(
                    context.l10n.numbersContinueAfterTheHighestNumberInThe,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.addFinancialYear),
                    subtitle: Text(
                      context.l10n.theIndianFinancialYearStartsOn1April,
                    ),
                    value: _financialYear,
                    onChanged: _saving
                        ? null
                        : (value) {
                            _financialYear = value;
                            _updatePreview();
                          },
                  ),
                  if (_preview != null)
                    FutureBuilder<List<String>>(
                      future: _preview,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            context.l10n.couldNotLoadTheNextDocumentNumbers,
                          );
                        }
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.l10n.nextInvoice(snapshot.data![0])),
                            Text(context.l10n.nextEstimate(snapshot.data![1])),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  IgnorePointer(
                    ignoring: _saving,
                    child: CustomFieldsCard(
                      initialFields: _defaults,
                      recentLabels: DocumentFieldPreferences.recent(
                        snapshot.data!,
                      ),
                      onChanged: (fields) => _defaults = fields,
                      labelsOnly: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: context.l10n.save,
                    onPressed: _save,
                    isLoading: _saving,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
