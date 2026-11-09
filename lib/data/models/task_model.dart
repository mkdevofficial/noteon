import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:noteon/core/utils/recurrence_engine.dart';

class TaskModel {
  final String id;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> roles;
  final String? listId; // Project list
  final String title;
  final String description;
  final String status; // 'todo', 'in_progress', 'done'
  final String priority; // 'none', 'low', 'medium', 'high', 'urgent'
  final DateTime? startAt;
  final DateTime? dueAt;
  final bool hasTime;
  final List<DateTime> remindAt;
  final RepeatRule? repeatRule;
  final List<String> labelIds;
  final String? parentTaskId; // Subtask if non-null
  final String? noteId; // Linked note
  final DateTime? completedAt;
  final int order;
  final int timeSpentSec;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.ownerId,
    required this.memberIds,
    required this.roles,
    this.listId,
    required this.title,
    this.description = '',
    this.status = 'todo',
    this.priority = 'none',
    this.startAt,
    this.dueAt,
    this.hasTime = false,
    this.remindAt = const [],
    this.repeatRule,
    this.labelIds = const [],
    this.parentTaskId,
    this.noteId,
    this.completedAt,
    this.order = 0,
    this.timeSpentSec = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDone => status == 'done';
  bool get isSubtask => parentTaskId != null && parentTaskId!.isNotEmpty;

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'memberIds': memberIds,
      'roles': roles,
      'listId': listId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'startAt': startAt != null ? Timestamp.fromDate(startAt!) : null,
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'hasTime': hasTime,
      'remindAt': remindAt.map((d) => Timestamp.fromDate(d)).toList(),
      'repeatRule': repeatRule?.toMap(),
      'labelIds': labelIds,
      'parentTaskId': parentTaskId,
      'noteId': noteId,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'order': order,
      'timeSpentSec': timeSpentSec,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return TaskModel.fromMap(map, doc.id);
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      memberIds:
          (map['memberIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      roles:
          (map['roles'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {},
      listId: map['listId'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'todo',
      priority: map['priority'] as String? ?? 'none',
      startAt: map['startAt'] is Timestamp
          ? (map['startAt'] as Timestamp).toDate()
          : null,
      dueAt: map['dueAt'] is Timestamp
          ? (map['dueAt'] as Timestamp).toDate()
          : null,
      hasTime: map['hasTime'] as bool? ?? false,
      remindAt:
          (map['remindAt'] as List<dynamic>?)
              ?.whereType<Timestamp>()
              .map((t) => t.toDate())
              .toList() ??
          [],
      repeatRule: map['repeatRule'] is Map<dynamic, dynamic>
          ? RepeatRule.fromMap(
              Map<String, dynamic>.from(map['repeatRule'] as Map),
            )
          : null,
      labelIds:
          (map['labelIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      parentTaskId: map['parentTaskId'] as String?,
      noteId: map['noteId'] as String?,
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      order: (map['order'] as num?)?.toInt() ?? 0,
      timeSpentSec: (map['timeSpentSec'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  TaskModel copyWith({
    String? listId,
    bool clearListId = false,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? startAt,
    bool clearStartAt = false,
    DateTime? dueAt,
    bool clearDueAt = false,
    bool? hasTime,
    List<DateTime>? remindAt,
    RepeatRule? repeatRule,
    bool clearRepeatRule = false,
    List<String>? labelIds,
    String? parentTaskId,
    bool clearParentTaskId = false,
    String? noteId,
    bool clearNoteId = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? order,
    int? timeSpentSec,
    DateTime? updatedAt,
    List<String>? memberIds,
    Map<String, String>? roles,
  }) {
    return TaskModel(
      id: id,
      ownerId: ownerId,
      memberIds: memberIds ?? this.memberIds,
      roles: roles ?? this.roles,
      listId: clearListId ? null : (listId ?? this.listId),
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startAt: clearStartAt ? null : (startAt ?? this.startAt),
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      hasTime: hasTime ?? this.hasTime,
      remindAt: remindAt ?? this.remindAt,
      repeatRule: clearRepeatRule ? null : (repeatRule ?? this.repeatRule),
      labelIds: labelIds ?? this.labelIds,
      parentTaskId: clearParentTaskId
          ? null
          : (parentTaskId ?? this.parentTaskId),
      noteId: clearNoteId ? null : (noteId ?? this.noteId),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      order: order ?? this.order,
      timeSpentSec: timeSpentSec ?? this.timeSpentSec,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
