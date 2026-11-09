import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteon/core/constants/app_constants.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/folder_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  void _showCreateOrEditFolderDialog(
    BuildContext context,
    WidgetRef ref,
    List<FolderModel> allFolders, [
    FolderModel? folder,
  ]) {
    final controller = TextEditingController(text: folder?.name ?? '');
    String? selectedParentId = folder?.parentId;
    int selectedColor =
        folder?.color ?? AppConstants.accentColors.first.toARGB32();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(folder == null ? 'New Folder' : 'Edit Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Folder Name',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
              const SizedBox(height: 12),
              // Optional parent folder (nestable folders)
              DropdownButtonFormField<String?>(
                initialValue: selectedParentId,
                decoration: const InputDecoration(
                  labelText: 'Parent Folder (Optional)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('None (Root level)'),
                  ),
                  for (final f in allFolders.where((f) => f.id != folder?.id))
                    DropdownMenuItem(value: f.id, child: Text(f.name)),
                ],
                onChanged: (val) => setState(() => selectedParentId = val),
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
                final repo = ref.read(foldersRepositoryProvider);

                if (folder == null) {
                  await repo.createFolder(
                    FolderModel(
                      id: '',
                      ownerId: uid,
                      name: name,
                      parentId: selectedParentId,
                      color: selectedColor,
                    ),
                  );
                } else {
                  await repo.updateFolder(
                    folder.copyWith(
                      name: name,
                      parentId: selectedParentId,
                      clearParentId: selectedParentId == null,
                      color: selectedColor,
                    ),
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

    final foldersRepo = ref.watch(foldersRepositoryProvider);
    final foldersStream = foldersRepo.watchFolders(uid: uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.folders ?? 'Folders')),
      body: SafeArea(
        child: StreamBuilder<List<FolderModel>>(
          stream: foldersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final folders = snapshot.data ?? [];
            if (folders.isEmpty) {
              return Center(
                child: Text(
                  'No folders created yet.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: folders.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final folder = folders[index];
                final isNested =
                    folder.parentId != null && folder.parentId!.isNotEmpty;

                return ListTile(
                  contentPadding: EdgeInsets.only(
                    left: isNested ? 32 : 16,
                    right: 16,
                  ),
                  leading: Icon(
                    isNested
                        ? Icons.subdirectory_arrow_right_rounded
                        : Icons.folder_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(folder.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showCreateOrEditFolderDialog(
                          context,
                          ref,
                          folders,
                          folder,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => foldersRepo.deleteFolder(folder.id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: StreamBuilder<List<FolderModel>>(
        stream: foldersStream,
        builder: (context, snap) => FloatingActionButton(
          onPressed: () =>
              _showCreateOrEditFolderDialog(context, ref, snap.data ?? []),
          child: const Icon(Icons.create_new_folder_outlined),
        ),
      ),
    );
  }
}
