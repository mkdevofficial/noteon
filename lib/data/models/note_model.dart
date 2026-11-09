import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> roles; // uid -> 'owner' | 'editor' | 'viewer'
  final String type; // 'text', 'checklist', 'markdown'
  final String title;
  final String bodyDelta; // Quill Delta JSON or checklist JSON
  final String plainText;
  final int color; // ARGB int
  final bool pinned;
  final bool archived;
  final DateTime? trashedAt;
  final List<String> labelIds;
  final String? folderId;
  final DateTime? reminderAt;
  final bool lockedLocalOnly;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const NoteModel({
    required this.id,
    required this.ownerId,
    required this.memberIds,
    required this.roles,
    this.type = 'text',
    this.title = '',
    this.bodyDelta = '',
    this.plainText = '',
    this.color = 0xFFFFFFFF,
    this.pinned = false,
    this.archived = false,
    this.trashedAt,
    this.labelIds = const [],
    this.folderId,
    this.reminderAt,
    this.lockedLocalOnly = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
  });

  bool get isTrashed => trashedAt != null;

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'memberIds': memberIds,
      'roles': roles,
      'type': type,
      'title': title,
      'bodyDelta': bodyDelta,
      'plainText': plainText,
      'color': color,
      'pinned': pinned,
      'archived': archived,
      'trashedAt': trashedAt != null ? Timestamp.fromDate(trashedAt!) : null,
      'labelIds': labelIds,
      'folderId': folderId,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
      'lockedLocalOnly': lockedLocalOnly,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'version': version,
    };
  }

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return NoteModel.fromMap(map, doc.id);
  }

  factory NoteModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteModel(
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
      type: map['type'] as String? ?? 'text',
      title: map['title'] as String? ?? '',
      bodyDelta: map['bodyDelta'] as String? ?? '',
      plainText: map['plainText'] as String? ?? '',
      color: (map['color'] as num?)?.toInt() ?? 0xFFFFFFFF,
      pinned: map['pinned'] as bool? ?? false,
      archived: map['archived'] as bool? ?? false,
      trashedAt: map['trashedAt'] is Timestamp
          ? (map['trashedAt'] as Timestamp).toDate()
          : null,
      labelIds:
          (map['labelIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      folderId: map['folderId'] as String?,
      reminderAt: map['reminderAt'] is Timestamp
          ? (map['reminderAt'] as Timestamp).toDate()
          : null,
      lockedLocalOnly: map['lockedLocalOnly'] as bool? ?? false,
      order: (map['order'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      version: (map['version'] as num?)?.toInt() ?? 1,
    );
  }

  NoteModel copyWith({
    String? type,
    String? title,
    String? bodyDelta,
    String? plainText,
    int? color,
    bool? pinned,
    bool? archived,
    DateTime? trashedAt,
    bool clearTrashedAt = false,
    List<String>? labelIds,
    String? folderId,
    bool clearFolderId = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    bool? lockedLocalOnly,
    int? order,
    DateTime? updatedAt,
    int? version,
    List<String>? memberIds,
    Map<String, String>? roles,
  }) {
    return NoteModel(
      id: id,
      ownerId: ownerId,
      memberIds: memberIds ?? this.memberIds,
      roles: roles ?? this.roles,
      type: type ?? this.type,
      title: title ?? this.title,
      bodyDelta: bodyDelta ?? this.bodyDelta,
      plainText: plainText ?? this.plainText,
      color: color ?? this.color,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      trashedAt: clearTrashedAt ? null : (trashedAt ?? this.trashedAt),
      labelIds: labelIds ?? this.labelIds,
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      lockedLocalOnly: lockedLocalOnly ?? this.lockedLocalOnly,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
