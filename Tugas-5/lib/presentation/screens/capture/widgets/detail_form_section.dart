import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/record_category.dart';
import '../../../../providers/capture_provider.dart';
import '../../../widgets/category_style.dart';
import '../../../widgets/section_card.dart';

class DetailFormSection extends StatelessWidget {
  const DetailFormSection({super.key, required this.titleController, required this.noteController});

  final TextEditingController titleController;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CaptureProvider>();

    return SectionCard(
      step: 3,
      title: 'Detail catatan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: titleController,
            maxLength: AppConstants.maxTitleLength,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: Validators.title,
            decoration: const InputDecoration(labelText: 'Judul'),
          ),
          const SizedBox(height: 8),
          Text('Kategori', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in RecordCategory.values)
                ChoiceChip(
                  avatar: Icon(c.icon, size: 16, color: c.color),
                  label: Text(c.label),
                  selected: provider.category == c,
                  onSelected: (_) => provider.setCategory(c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: noteController,
            maxLength: AppConstants.maxNoteLength,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            validator: Validators.note,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)', alignLabelWithHint: true),
          ),
        ],
      ),
    );
  }
}
