import '../../features/progress/models/user_progress_summary.dart';
import 'firestore_progress_service.dart';

class ProgressService {
  final FirestoreProgressService _firestoreProgress;

  ProgressService({
    FirestoreProgressService? firestoreProgress,
  }) : _firestoreProgress = firestoreProgress ?? FirestoreProgressService();

  Future<UserProgressSummary?> loadProgressSummary() {
    return _firestoreProgress.getSummary();
  }
}
