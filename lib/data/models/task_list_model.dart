import 'package:cloud_firestore/cloud_firestore.dart';

class TaskListModel {
  final String id;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> roles;
  final String name;
  final int color;
  final String icon;
  final bool archived;
  final int order;

  const TaskListModel({
    required this.id,
    required this.ownerId,
    required this.memberIds,
    required this.roles,
    required this.name,
    this.color = 0xFF4A6572,
    this.icon = 'list',
    this.archived = false,
    this.order = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'memberIds': memberIds,
      'roles': roles,
      'name': name,
      'color': color,
      'icon': icon,
      'archived': archived,
      'order': order,
    };
  }

  factory TaskListModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return TaskListModel.fromMap(map, doc.id);
  }

  factory TaskListModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskListModel(
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
      name: map['name'] as String? ?? '',
      color: (map['color'] as num?)?.toInt() ?? 0xFF4A6572,
      icon: map['icon'] as String? ?? 'list',
      archived: map['archived'] as bool? ?? false,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  TaskListModel copyWith({
    String? name,
    int? color,
    String? icon,
    bool? archived,
    int? order,
    List<String>? memberIds,
    Map<String, String>? roles,
  }) {
    return TaskListModel(
      id: id,
      ownerId: ownerId,
      memberIds: memberIds ?? this.memberIds,
      roles: roles ?? this.roles,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      archived: archived ?? this.archived,
      order: order ?? this.order,
    );
  }
}
