import 'package:flutter_test/flutter_test.dart';
import 'package:noteon/core/utils/conflict_handler.dart';

void main() {
  group('ConflictHandler Tests', () {
    final now = DateTime.now();

    test('No conflict when versions and content match exactly', () {
      final local = NoteConflictPayload(
        id: 'n1',
        title: 'Title',
        bodyDelta: 'body',
        version: 2,
        updatedAt: now,
        authorId: 'u1',
      );
      final remote = NoteConflictPayload(
        id: 'n1',
        title: 'Title',
        bodyDelta: 'body',
        version: 2,
        updatedAt: now,
        authorId: 'u1',
      );

      final res = ConflictHandler.resolveNoteConflict(
        local: local,
        remote: remote,
        baseVersion: 2,
      );

      expect(res.winner, equals(ConflictWinner.noConflict));
      expect(res.itemToArchive, isNull);
    });

    test('Local wins cleanly when remote has not incremented past baseVersion', () {
      final local = NoteConflictPayload(
        id: 'n1',
        title: 'Updated locally',
        bodyDelta: 'new body',
        version: 3,
        updatedAt: now,
        authorId: 'u1',
      );
      final remote = NoteConflictPayload(
        id: 'n1',
        title: 'Original',
        bodyDelta: 'original body',
        version: 2,
        updatedAt: now.subtract(const Duration(hours: 1)),
        authorId: 'u1',
      );

      final res = ConflictHandler.resolveNoteConflict(
        local: local,
        remote: remote,
        baseVersion: 2,
      );

      expect(res.winner, equals(ConflictWinner.local));
      expect(res.winningItem.title, equals('Updated locally'));
      expect(res.itemToArchive, isNull);
    });

    test('Concurrent conflict: local is newer than remote -> local wins, remote archived', () {
      final local = NoteConflictPayload(
        id: 'n1',
        title: 'Local concurrent edit',
        bodyDelta: 'local body',
        version: 3,
        updatedAt: now, // newer
        authorId: 'u1',
      );
      final remote = NoteConflictPayload(
        id: 'n1',
        title: 'Remote concurrent edit',
        bodyDelta: 'remote body',
        version: 3,
        updatedAt: now.subtract(const Duration(minutes: 5)), // older
        authorId: 'u2',
      );

      final res = ConflictHandler.resolveNoteConflict(
        local: local,
        remote: remote,
        baseVersion: 1, // both bumped past version 1
      );

      expect(res.winner, equals(ConflictWinner.local));
      expect(res.winningItem.title, equals('Local concurrent edit'));
      expect(res.itemToArchive, isNotNull);
      expect(res.itemToArchive?.title, equals('Remote concurrent edit'));
    });

    test('Concurrent conflict: remote is newer than local -> remote wins, local archived', () {
      final local = NoteConflictPayload(
        id: 'n1',
        title: 'Local offline edit',
        bodyDelta: 'offline body',
        version: 2,
        updatedAt: now.subtract(const Duration(minutes: 10)),
        authorId: 'u1',
      );
      final remote = NoteConflictPayload(
        id: 'n1',
        title: 'Remote newer edit',
        bodyDelta: 'remote fresh body',
        version: 3,
        updatedAt: now,
        authorId: 'u2',
      );

      final res = ConflictHandler.resolveNoteConflict(
        local: local,
        remote: remote,
        baseVersion: 1,
      );

      expect(res.winner, equals(ConflictWinner.remote));
      expect(res.winningItem.title, equals('Remote newer edit'));
      expect(res.itemToArchive, isNotNull);
      expect(res.itemToArchive?.title, equals('Local offline edit'));
    });
  });
}
