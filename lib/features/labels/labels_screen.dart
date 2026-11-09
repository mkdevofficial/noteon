import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteon/core/constants/app_constants.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/label_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class LabelsScreen extends ConsumerWidget {
  const LabelsScreen({super.key});

  void _showCreateOrEditLabelDialog(
    BuildContext context,
    WidgetRef ref, [
    LabelModel? label,
  ]) {
    final controller = TextEditingController(text: label?.name ?? '');
    int selectedColor =
        label?.color ?? AppConstants.accentColors.first.toARGB32();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(label == null ? 'New Label' : 'Edit Label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Label Name',
                  prefixText: '#',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in AppConstants.accentColors)
                    GestureDetector(
                      onTap: () => setState(() => selectedColor = c.toARGB32()),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == c.toARGB32()
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selectedColor == c.toARGB32()
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final user =
                    ref.read(authStateProvider).valueOrNull ??
                    ref.read(authRepositoryProvider).currentUser;
                final uid = user?.uid ?? 'guest_user';
                final repo = ref.read(labelsRepositoryProvider);

                if (label == null) {
                  await repo.createLabel(
                    LabelModel(
                      id: '',
                      ownerId: uid,
                      name: name,
                      color: selectedColor,
                    ),
                  );
                } else {
                  await repo.updateLabel(
                    label.copyWith(name: name, color: selectedColor),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final labelsRepo = ref.watch(labelsRepositoryProvider);
    final labelsStream = labelsRepo.watchLabels(uid: uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.labels ?? 'Labels')),
      body: SafeArea(
        child: StreamBuilder<List<LabelModel>>(
          stream: labelsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final labels = snapshot.data ?? [];
            if (labels.isEmpty) {
              return Center(
                child: Text(
                  'No labels created yet.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: labels.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final label = labels[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(label.color),
                    radius: 12,
                  ),
                  title: Text('#${label.name}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _showCreateOrEditLabelDialog(context, ref, label),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => labelsRepo.deleteLabel(label.id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrEditLabelDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
