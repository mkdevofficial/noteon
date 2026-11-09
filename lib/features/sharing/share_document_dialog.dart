import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/providers/repository_providers.dart';
import 'package:noteon/data/repositories/sharing_repository.dart';

class ShareDocumentDialog extends ConsumerStatefulWidget {
  final String collection; // 'notes' or 'taskLists'
  final String documentId;
  final Map<String, String> roles;

  const ShareDocumentDialog({
    super.key,
    required this.collection,
    required this.documentId,
    required this.roles,
  });

  static Future<void> show({
    required BuildContext context,
    required String collection,
    required String documentId,
    required Map<String, String> roles,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareDocumentDialog(
        collection: collection,
        documentId: documentId,
        roles: roles,
      ),
    );
  }

  @override
  ConsumerState<ShareDocumentDialog> createState() =>
      _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends ConsumerState<ShareDocumentDialog> {
  final _emailController = TextEditingController();
  String _selectedRole = 'editor';
  bool _isLoading = false;
  List<CollaboratorInfo> _collaborators = [];

  @override
  void initState() {
    super.initState();
    _loadCollaborators();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCollaborators() async {
    final sharingRepo = ref.read(sharingRepositoryProvider);
    final list = await sharingRepo.fetchCollaboratorProfiles(
      roles: widget.roles,
    );
    if (mounted) {
      setState(() => _collaborators = list);
    }
  }

  Future<void> _share() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _isLoading = true);
    final sharingRepo = ref.read(sharingRepositoryProvider);
    final res = await sharingRepo.shareDocumentByEmail(
      collection: widget.collection,
      documentId: widget.documentId,
      targetEmail: email,
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.isSuccess) {
      _emailController.clear();
      _loadCollaborators();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shared successfully with $email')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.exceptionOrNull?.message ?? 'Sharing failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _revoke(String uid) async {
    final sharingRepo = ref.read(sharingRepositoryProvider);
    await sharingRepo.revokeCollaboratorAccess(
      collection: widget.collection,
      documentId: widget.documentId,
      targetUid: uid,
    );
    setState(() {
      _collaborators.removeWhere((c) => c.uid == uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.collaborators ?? 'Collaborators',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Email input & Role dropdown
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'user@example.com',
                    prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedRole,
                items: [
                  DropdownMenuItem(
                    value: 'editor',
                    child: Text(l10n?.roleEditor ?? 'Editor'),
                  ),
                  DropdownMenuItem(
                    value: 'viewer',
                    child: Text(l10n?.roleViewer ?? 'Viewer'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isLoading ? null : _share,
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n?.share ?? 'Invite'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Collaborators List
          Text(
            'People with access:',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: _collaborators.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No collaborators yet.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _collaborators.length,
                    itemBuilder: (ctx, idx) {
                      final c = _collaborators[idx];
                      final isOwner = c.role == 'owner';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            c.displayName.isNotEmpty
                                ? c.displayName[0].toUpperCase()
                                : 'U',
                          ),
                        ),
                        title: Text(c.displayName),
                        subtitle: Text(c.email ?? c.role),
                        trailing: isOwner
                            ? Chip(label: Text(l10n?.roleOwner ?? 'Owner'))
                            : IconButton(
                                icon: const Icon(
                                  Icons.person_remove_outlined,
                                  color: Colors.red,
                                ),
                                tooltip: l10n?.removeCollaborator ?? 'Remove',
                                onPressed: () => _revoke(c.uid),
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
