import 'package:cloud_firestore/cloud_firestore.dart';

class SavedSearchModel {
  final String id;
  final String ownerId;
  final String name;
  final String query;
  final Map<String, dynamic> filters;

  const SavedSearchModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.query,
    this.filters = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'query': query,
      'filters': filters,
    };
  }

  factory SavedSearchModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return SavedSearchModel.fromMap(map, doc.id);
  }

  factory SavedSearchModel.fromMap(Map<String, dynamic> map, String id) {
    return SavedSearchModel(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      query: map['query'] as String? ?? '',
      filters:
          (map['filters'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          {},
    );
  }
}
