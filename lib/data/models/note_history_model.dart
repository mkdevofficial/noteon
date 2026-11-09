import 'package:cloud_firestore/cloud_firestore.dart';

class NoteHistoryModel {
  final String id;
  final String title;
  final String bodyDelta;
  final DateTime savedAt;
  final String savedBy;

  const NoteHistoryModel({
    required this.id,
    required this.title,
    required this.bodyDelta,
    required this.savedAt,
    required this.savedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'bodyDelta': bodyDelta,
      'savedAt': Timestamp.fromDate(savedAt),
      'savedBy': savedBy,
    };
  }

  factory NoteHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return NoteHistoryModel.fromMap(map, doc.id);
  }

  factory NoteHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return NoteHistoryModel(
      id: id,
      title: map['title'] as String? ?? '',
      bodyDelta: map['bodyDelta'] as String? ?? '',
      savedAt: map['savedAt'] is Timestamp
          ? (map['savedAt'] as Timestamp).toDate()
          : DateTime.now(),
      savedBy: map['savedBy'] as String? ?? '',
    );
  }
}
