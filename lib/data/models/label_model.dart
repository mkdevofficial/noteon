import 'package:cloud_firestore/cloud_firestore.dart';

class LabelModel {
  final String id;
  final String ownerId;
  final String name;
  final int color;

  const LabelModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.color = 0xFF4A6572,
  });

  Map<String, dynamic> toFirestore() {
    return {'ownerId': ownerId, 'name': name, 'color': color};
  }

  factory LabelModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return LabelModel.fromMap(map, doc.id);
  }

  factory LabelModel.fromMap(Map<String, dynamic> map, String id) {
    return LabelModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      color: (map['color'] as num?)?.toInt() ?? 0xFF4A6572,
    );
  }

  LabelModel copyWith({String? name, int? color}) {
    return LabelModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}
