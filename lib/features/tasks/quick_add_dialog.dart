import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/core/utils/natural_language_parser.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class QuickAddDialog extends ConsumerStatefulWidget {
  const QuickAddDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickAddDialog(),
    );
  }

  @override
  ConsumerState<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends ConsumerState<QuickAddDialog> {
  final _controller = TextEditingController();
  ParsedTaskInput _parsed = const ParsedTaskInput(title: '');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    setState(() {
      _parsed = NaturalLanguageParser.parse(text);
    });
  }

  Future<void> _submit() async {
    if (_parsed.title.trim().isEmpty) return;

    final user =
        ref.read(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final task = TaskModel(
      id: '',
      ownerId: uid,
      memberIds: [uid],
      roles: {uid: 'owner'},
      title: _parsed.title,
      priority: _parsed.priority,
      dueAt: _parsed.dueAt,
      hasTime: _parsed.hasTime,
      labelIds: _parsed.labels,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final repo = ref.read(tasksRepositoryProvider);
    await repo.createTask(task);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task added: ${_parsed.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
                l10n?.quickAdd ?? 'Quick Add Task',
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
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText:
                  l10n?.quickAddHint ??
                  'e.g. Call Ahmed tomorrow 5pm !high #work',
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded),
                onPressed: _controller.text.trim().isEmpty ? null : _submit,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Live Extracted Preview Chips
          if (_controller.text.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (_parsed.dueAt != null)
                  Chip(
                    avatar: const Icon(Icons.event_outlined, size: 16),
                    label: Text(
                      _parsed.hasTime
                          ? DateFormat('EEE, MMM d • h:mm a')
                                .format(_parsed.dueAt!)
                          : DateFormat('EEE, MMM d').format(_parsed.dueAt!),
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                if (_parsed.priority != 'none')
                  Chip(
                    avatar: Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color:
                          _parsed.priority == 'urgent' ||
                              _parsed.priority == 'high'
                          ? Colors.red
                          : Colors.orange,
                    ),
                    label: Text(
                      _parsed.priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            _parsed.priority == 'urgent' ||
                                _parsed.priority == 'high'
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                for (final label in _parsed.labels)
                  Chip(
                    avatar: const Icon(Icons.label_outline, size: 16),
                    label: Text(
                      '#$label',
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Quick Examples
          Text(
            'Try an example:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('Call Ahmed tomorrow 5pm !high #work'),
                  onPressed: () {
                    _controller.text = 'Call Ahmed tomorrow 5pm !high #work';
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('الاتصال بأحمد غداً 5 مساءً !عاجل #عمل'),
                  onPressed: () {
                    _controller.text = 'الاتصال بأحمد غداً 5 مساءً !عاجل #عمل';
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Buy groceries today !medium #shopping'),
                  onPressed: () {
                    _controller.text = 'Buy groceries today !medium #shopping';
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
