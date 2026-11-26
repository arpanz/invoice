import 'package:flutter/material.dart';
import '../../../core/localization/l10n.dart';

import '../../../core/theme/app_icons.dart';
import '../models/document_custom_field.dart';

class CustomFieldsCard extends StatefulWidget {
  const CustomFieldsCard({
    super.key,
    required this.initialFields,
    required this.onChanged,
    this.recentLabels = const [],
    this.labelsOnly = false,
  });

  final List<DocumentCustomField> initialFields;
  final ValueChanged<List<DocumentCustomField>> onChanged;
  final List<String> recentLabels;
  final bool labelsOnly;

  @override
  State<CustomFieldsCard> createState() => _CustomFieldsCardState();
}

class _CustomFieldsCardState extends State<CustomFieldsCard> {
  late final _fields = {
    for (final field in widget.initialFields.take(
      DocumentCustomField.maxFields,
    ))
      UniqueKey(): field,
  };

  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged(_fields.values.toList(growable: false));
  }

  void _add([String label = '']) {
    _update(() => _fields[UniqueKey()] = DocumentCustomField(label: label));
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _fields.length < DocumentCustomField.maxFields;
    final active = _fields.values
        .map((field) => field.label.trim().toLowerCase())
        .toSet();
    final suggestions = widget.recentLabels.where(
      (label) => !active.contains(label.toLowerCase()),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.labelsOnly ? context.l10n.defaultInvoiceFields : context.l10n.customFields,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.labelsOnly)
              Text(
                context.l10n.theseLabelsAppearOnNewInvoicesWithEmpty,
              ),
            for (final entry in _fields.entries)
              Padding(
                key: entry.key,
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: entry.value.label,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: context.l10n.label,
                            ),
                            onChanged: (label) => _update(() {
                              _fields[entry.key] = DocumentCustomField(
                                label: label,
                                value: _fields[entry.key]!.value,
                              );
                            }),
                          ),
                          if (!widget.labelsOnly)
                            TextFormField(
                              initialValue: entry.value.value,
                              decoration: InputDecoration(
                                labelText: context.l10n.value,
                              ),
                              onChanged: (value) => _update(() {
                                _fields[entry.key] = DocumentCustomField(
                                  label: _fields[entry.key]!.label,
                                  value: value,
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.removeField,
                      icon: const Icon(AppIcons.close),
                      onPressed: () => _update(() => _fields.remove(entry.key)),
                    ),
                  ],
                ),
              ),
            if (canAdd && suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final label in suggestions)
                      ActionChip(
                        label: Text(label),
                        onPressed: () => _add(label),
                      ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: canAdd ? _add : null,
              icon: const Icon(AppIcons.add),
              label: Text(context.l10n.addField),
            ),
          ],
        ),
      ),
    );
  }
}
