import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String locale;
  final String theme;
  final bool isAnonymous;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.locale = 'en',
    this.theme = 'system',
    this.isAnonymous = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'locale': locale,
      'theme': theme,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      locale: map['locale'] as String? ?? 'en',
      theme: map['theme'] as String? ?? 'system',
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    String? locale,
    String? theme,
    bool? isAnonymous,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      locale: locale ?? this.locale,
      theme: theme ?? this.theme,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt,
    );
  }
}
