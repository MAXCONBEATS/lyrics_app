import 'package:flutter/material.dart';
import '../../models/section.dart';

class SectionEditor extends StatelessWidget {
  final SongSection section;
  final ValueChanged<SongSection> onChanged;
  final VoidCallback onDelete;

  const SectionEditor({
    super.key,
    required this.section,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<SectionType>(
                    value: section.type,
                    items: SectionType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t == SectionType.custom
                          ? (section.customLabel ?? 'custom')
                          : t.name),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        onChanged(SongSection(
                          type: val,
                          text: section.text,
                          customLabel: val == SectionType.custom ? 'Solo' : null,
                          sortOrder: section.sortOrder,
                        ));
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Тип'),
                  ),
                ),
                if (section.type == SectionType.custom)
                  Expanded(
                    child: TextFormField(
                      initialValue: section.customLabel ?? '',
                      onChanged: (v) => onChanged(SongSection(
                        type: section.type,
                        text: section.text,
                        customLabel: v,
                        sortOrder: section.sortOrder,
                      )),
                      decoration: const InputDecoration(labelText: 'Название типа'),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            TextFormField(
              initialValue: section.text,
              maxLines: 4,
              onChanged: (v) => onChanged(SongSection(
                type: section.type,
                text: v,
                customLabel: section.customLabel,
                sortOrder: section.sortOrder,
              )),
              decoration: const InputDecoration(labelText: 'Текст'),
            ),
          ],
        ),
      ),
    );
  }
}