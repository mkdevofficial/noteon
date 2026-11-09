enum ConflictWinner { local, remote, noConflict }

class ConflictResolution<T> {
  final ConflictWinner winner;
  final T winningItem;
  final T? itemToArchive; // The losing version to be preserved in history

  const ConflictResolution({
    required this.winner,
    required this.winningItem,
    this.itemToArchive,
  });
}

class NoteConflictPayload {
  final String id;
  final String title;
  final String bodyDelta;
  final int version;
  final DateTime updatedAt;
  final String authorId;

  const NoteConflictPayload({
    required this.id,
    required this.title,
    required this.bodyDelta,
    required this.version,
    required this.updatedAt,
    required this.authorId,
  });
}

class ConflictHandler {
  /// Resolves conflicts between local uncommitted edits and remote Firestore state.
  /// Last write wins by `updatedAt`, but the losing version is never lost and is
  /// preserved in note history.
  static ConflictResolution<NoteConflictPayload> resolveNoteConflict({
    required NoteConflictPayload local,
    required NoteConflictPayload remote,
    required int baseVersion,
  }) {
    // If versions match and contents match, there's no conflict
    if (local.version == remote.version &&
        local.title == remote.title &&
        local.bodyDelta == remote.bodyDelta) {
      return ConflictResolution(
        winner: ConflictWinner.noConflict,
        winningItem: local,
      );
    }

    // If remote version hasn't changed since local base version, local cleanly wins
    if (remote.version <= baseVersion) {
      return ConflictResolution(
        winner: ConflictWinner.local,
        winningItem: local,
      );
    }

    // A concurrent or offline edit occurred on both sides.
    // Compare timestamps (last write wins)
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      // Local is newer -> local wins, but save remote into history
      return ConflictResolution(
        winner: ConflictWinner.local,
        winningItem: local,
        itemToArchive: remote,
      );
    } else {
      // Remote is newer or equal -> remote wins, but save local into history
      return ConflictResolution(
        winner: ConflictWinner.remote,
        winningItem: remote,
        itemToArchive: local,
      );
    }
  }
}
