import 'package:cloud_firestore/cloud_firestore.dart';

class FolderModel {
  final String id;
  final String ownerId;
  final String name;
  final String? parentId; // Nestable folders
  final int color;
  final int order;

  const FolderModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.parentId,
    this.color = 0xFF4A6572,
    this.order = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'parentId': parentId,
      'color': color,
      'order': order,
    };
  }

  factory FolderModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return FolderModel.fromMap(map, doc.id);
  }

  factory FolderModel.fromMap(Map<String, dynamic> map, String id) {
    return FolderModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      parentId: map['parentId'] as String?,
      color: (map['color'] as num?)?.toInt() ?? 0xFF4A6572,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  FolderModel copyWith({
    String? name,
    String? parentId,
    bool clearParentId = false,
    int? color,
    int? order,
  }) {
    return FolderModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      color: color ?? this.color,
      order: order ?? this.order,
    );
  }
}
