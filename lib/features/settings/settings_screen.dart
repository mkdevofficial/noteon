import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/core/constants/app_constants.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/core/l10n/locale_provider.dart';
import 'package:noteon/core/theme/app_theme.dart';
import 'package:noteon/core/theme/theme_provider.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';
import 'package:noteon/features/export_import/export_import_service.dart';
import 'package:noteon/features/reminders/reminder_service.dart';
import 'package:noteon/features/settings/app_lock_service.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TimeOfDay _agendaTime = const TimeOfDay(hour: 8, minute: 30);
  bool _dailyAgendaEnabled = false;

  void _showAccentColorPicker() {
    final currentAccent = ref.read(themeProvider).accentColor;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Accent Color',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final c in AppConstants.accentColors)
                  InkWell(
                    onTap: () {
                      ref.read(themeProvider.notifier).setAccentColor(c);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: currentAccent == c
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: currentAccent == c
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    final user =
        ref.read(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final notes = await ref
        .read(notesRepositoryProvider)
        .watchNotes(uid: uid)
        .first;
    final tasks = await ref
        .read(tasksRepositoryProvider)
        .watchTasks(uid: uid)
        .first;
    final lists = await ref
        .read(taskListsRepositoryProvider)
        .watchTaskLists(uid: uid)
        .first;
    final labels = await ref
        .read(labelsRepositoryProvider)
        .watchLabels(uid: uid)
        .first;
    final folders = await ref
        .read(foldersRepositoryProvider)
        .watchFolders(uid: uid)
        .first;

    final jsonBackup = ExportImportService.exportAllToJson(
      notes: notes,
      tasks: tasks,
      lists: lists,
      labels: labels,
      folders: folders,
    );

    await SharePlus.instance.share(
      ShareParams(
        text: jsonBackup,
        subject: 'NoteOn_Backup_${DateTime.now().toIso8601String()}.json',
      ),
    );
  }

  Future<void> _importBackup() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt', 'md'],
      );

      if (files.isNotEmpty) {
        final content = await files.first.xFile.readAsString();
        final parsed = ExportImportService.parseJsonBackup(content);
        if (parsed != null && parsed['notes'] is List) {
          final notes = (parsed['notes'] as List)
              .map(
                (m) =>
                    NoteModel.fromMap(Map<String, dynamic>.from(m as Map), ''),
              )
              .toList();
          await ref.read(notesRepositoryProvider).batchImportNotes(notes);

          if (parsed['tasks'] is List) {
            final tasks = (parsed['tasks'] as List)
                .map(
                  (m) => TaskModel.fromMap(
                    Map<String, dynamic>.from(m as Map),
                    '',
                  ),
                )
                .toList();
            await ref.read(tasksRepositoryProvider).batchImportTasks(tasks);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup imported successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _upgradeAccount() async {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upgrade Anonymous Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Link an email and password to preserve your notes across all your devices.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
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
              final email = emailController.text.trim();
              final pass = passController.text;
              if (email.isNotEmpty && pass.length >= 6) {
                Navigator.pop(ctx);
                final res = await ref
                    .read(authRepositoryProvider)
                    .upgradeAnonymousWithEmail(email: email, password: pass);
                if (mounted) {
                  if (res.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account successfully linked!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          res.exceptionOrNull?.message ?? 'Linking failed',
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Link Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteAccount ?? 'Delete Account'),
        content: Text(
          l10n?.deleteAccountConfirm ?? 'Are you sure? This will permanently delete your account, notes, and tasks. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authRepositoryProvider).deleteAccount('');
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final themeSettings = ref.watch(themeProvider);
    final appLockState = ref.watch(appLockProvider);
    final currentLocale = ref.watch(localeProvider);

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settingsTitle ?? 'Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // User Account Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'NoteOn User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.isAnonymous == true
                                ? 'Guest (Unlinked Account)'
                                : (user?.email ?? 'user@noteon.app'),
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user?.isAnonymous == true)
                      FilledButton.tonal(
                        onPressed: _upgradeAccount,
                        child: const Text('Upgrade'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Appearance & Themes Section
            Text(
              'Appearance',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.brightness_6_rounded),
                    title: Text(l10n?.theme ?? 'Theme'),
                    trailing: DropdownButton<AppThemeMode>(
                      value: themeSettings.themeMode,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: AppThemeMode.system,
                          child: Text(l10n?.themeSystem ?? 'System'),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.light,
                          child: Text(l10n?.themeLight ?? 'Light'),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.dark,
                          child: Text(l10n?.themeDark ?? 'Dark'),
                        ),
                        DropdownMenuItem(
                          value: AppThemeMode.amoled,
                          child: Text(l10n?.themeAmoled ?? 'AMOLED Black'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeProvider.notifier).setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.color_lens_outlined),
                    title: Text(l10n?.accentColor ?? 'Accent Color'),
                    trailing: CircleAvatar(
                      backgroundColor: themeSettings.accentColor,
                      radius: 12,
                    ),
                    onTap: _showAccentColorPicker,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.translate_rounded),
                    title: Text(l10n?.language ?? 'Language'),
                    trailing: DropdownButton<String?>(
                      value: currentLocale?.languageCode,
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(l10n?.languageEnglish ?? 'English'),
                        ),
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text(
                            l10n?.languageArabic ?? 'العربية (Arabic)',
                          ),
                        ),
                      ],
                      onChanged: (lang) {
                        ref.read(localeProvider.notifier).setLocale(lang);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.format_size_rounded),
                    title: Text(l10n?.fontSize ?? 'Font Size Scale'),
                    subtitle: Slider(
                      value: themeSettings.fontScale,
                      min: 0.85,
                      max: 1.3,
                      divisions: 3,
                      label: '${(themeSettings.fontScale * 100).toInt()}%',
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).setFontScale(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Security & App Lock Section
            Text(
              'Security',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint_rounded),
                    title: Text(l10n?.appLock ?? 'App Lock (Biometrics/PIN)'),
                    subtitle: Text(
                      l10n?.appLockDesc ??
                          'Require authentication when opening app',
                    ),
                    value: appLockState.isAppLockEnabled,
                    onChanged: (enabled) {
                      ref
                          .read(appLockProvider.notifier)
                          .setAppLockEnabled(enabled);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notifications Section
            Text(
              'Notifications',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.alarm_rounded),
                    title: Text(
                      l10n?.dailyAgendaNotification ??
                          'Daily Agenda Notification',
                    ),
                    subtitle: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _agendaTime,
                        );
                        if (picked != null) {
                          setState(() => _agendaTime = picked);
                          if (_dailyAgendaEnabled) {
                            await ReminderService.instance.scheduleDailyAgenda(
                              hour: picked.hour,
                              minute: picked.minute,
                              taskCount: 3,
                            );
                          }
                        }
                      },
                      child: Text(
                        '${_agendaTime.format(context)} morning overview (tap to change)',
                      ),
                    ),
                    value: _dailyAgendaEnabled,
                    onChanged: (val) async {
                      setState(() => _dailyAgendaEnabled = val);
                      if (val) {
                        await ReminderService.instance.scheduleDailyAgenda(
                          hour: _agendaTime.hour,
                          minute: _agendaTime.minute,
                          taskCount: 3,
                        );
                      } else {
                        await ReminderService.instance.cancelDailyAgenda();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Data & Backup Section
            Text(
              'Data & Backup',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: Text(l10n?.exportData ?? 'Export All Data (JSON)'),
                    onTap: _exportBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: Text(
                      l10n?.importData ?? 'Import Data (JSON/Text/MD)',
                    ),
                    onTap: _importBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.insights_rounded),
                    title: Text(
                      l10n?.statistics ?? 'Productivity & Statistics',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                    onTap: () => context.push('/stats'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account Actions
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: Text(l10n?.signOut ?? 'Sign Out'),
                    onTap: _signOut,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      l10n?.deleteAccount ?? 'Delete Account',
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
