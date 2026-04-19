import 'package:cloud_firestore/cloud_firestore.dart';

enum TutorRole { user, tutor }

class TutorMessage {
  final String id;
  final TutorRole role;
  final String text;
  final DateTime createdAt;

  const TutorMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role == TutorRole.user ? 'user' : 'tutor',
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TutorMessage.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return TutorMessage(
      id: id,
      role: (data['role'] ?? 'user') == 'tutor' ? TutorRole.tutor : TutorRole.user,
      text: (data['text'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
