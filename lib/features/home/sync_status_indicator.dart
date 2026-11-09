import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final hasFirebase = ref.watch(isFirebaseAvailableProvider);
    final l10n = AppLocalizations.of(context);

    if (!hasFirebase) {
      return Tooltip(
        message: 'Offline / Local Demo Mode',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.offline_pin_outlined,
                size: 16,
                color: Colors.orange[400],
              ),
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(fontSize: 11, color: Colors.orange[400]),
              ),
            ],
          ),
        ),
      );
    }

    final (icon, color, text) = switch (status) {
      SyncStatus.synced => (
        Icons.cloud_done_rounded,
        Colors.green[400],
        l10n?.syncStatusSynced ?? 'Synced',
      ),
      SyncStatus.syncing => (
        Icons.cloud_sync_rounded,
        Colors.blue[400],
        l10n?.syncStatusSyncing ?? 'Syncing...',
      ),
      SyncStatus.offline => (
        Icons.cloud_off_rounded,
        Colors.amber[400],
        l10n?.syncStatusOffline ?? 'Offline',
      ),
      SyncStatus.error => (
        Icons.sync_problem_rounded,
        Colors.red[400],
        l10n?.syncStatusError ?? 'Sync Error',
      ),
    };

    return Tooltip(
      message: text,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
