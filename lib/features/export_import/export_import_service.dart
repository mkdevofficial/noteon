import 'dart:convert';
import 'dart:typed_data';

import 'package:noteon/data/models/folder_model.dart';
import 'package:noteon/data/models/label_model.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/data/models/task_list_model.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportImportService {
  /// Exports all user data as a formatted JSON string backup.
  static String exportAllToJson({
    required List<NoteModel> notes,
    required List<TaskModel> tasks,
    required List<TaskListModel> lists,
    required List<LabelModel> labels,
    required List<FolderModel> folders,
  }) {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes
          .map(
            (n) => {
              'id': n.id,
              'title': n.title,
              'plainText': n.plainText,
              'bodyDelta': n.bodyDelta,
              'type': n.type,
              'color': n.color,
              'pinned': n.pinned,
              'archived': n.archived,
              'labelIds': n.labelIds,
              'folderId': n.folderId,
              'createdAt': n.createdAt.toIso8601String(),
              'updatedAt': n.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'tasks': tasks
          .map(
            (t) => {
              'id': t.id,
              'title': t.title,
              'description': t.description,
              'status': t.status,
              'priority': t.priority,
              'dueAt': t.dueAt?.toIso8601String(),
              'listId': t.listId,
              'labelIds': t.labelIds,
              'parentTaskId': t.parentTaskId,
              'noteId': t.noteId,
              'completedAt': t.completedAt?.toIso8601String(),
              'timeSpentSec': t.timeSpentSec,
            },
          )
          .toList(),
      'taskLists': lists
          .map(
            (l) => {
              'id': l.id,
              'name': l.name,
              'color': l.color,
              'icon': l.icon,
            },
          )
          .toList(),
      'labels': labels
          .map((lb) => {'id': lb.id, 'name': lb.name, 'color': lb.color})
          .toList(),
      'folders': folders
          .map(
            (f) => {
              'id': f.id,
              'name': f.name,
              'parentId': f.parentId,
              'color': f.color,
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exports tasks into standard CSV format.
  static String exportTasksToCsv(List<TaskModel> tasks) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Title,Description,Status,Priority,Due Date,List ID,Completed At',
    );
    for (final t in tasks) {
      final safeTitle = '"${t.title.replaceAll('"', '""')}"';
      final safeDesc = '"${t.description.replaceAll('"', '""')}"';
      final dueStr = t.dueAt?.toIso8601String() ?? '';
      final compStr = t.completedAt?.toIso8601String() ?? '';
      buffer.writeln(
        '${t.id},$safeTitle,$safeDesc,${t.status},${t.priority},$dueStr,${t.listId ?? ""},$compStr',
      );
    }
    return buffer.toString();
  }

  /// Exports a note to Markdown format.
  static String exportNoteToMarkdown(NoteModel note) {
    final buffer = StringBuffer();
    buffer.writeln('# ${note.title}');
    buffer.writeln();
    buffer.writeln(
      '> Created: ${note.createdAt.toIso8601String()} | Updated: ${note.updatedAt.toIso8601String()}',
    );
    buffer.writeln();
    buffer.writeln(note.plainText);
    return buffer.toString();
  }

  /// Generates a PDF document for a note.
  static Future<Uint8List> exportNoteToPdf(NoteModel note) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                note.title.isNotEmpty ? note.title : 'Untitled Note',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'NoteOn • ${note.createdAt.year}-${note.createdAt.month.toString().padLeft(2, '0')}-${note.createdAt.day.toString().padLeft(2, '0')}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Divider(thickness: 1, height: 24),
              pw.SizedBox(height: 12),
              pw.Text(
                note.plainText,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Parses JSON backup for importing.
  static Map<String, dynamic>? parseJsonBackup(String jsonStr) {
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }
}
