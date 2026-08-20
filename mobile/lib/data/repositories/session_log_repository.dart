import '../models/session_log.dart';
import 'base_repository.dart';

/// Records that a client completed a session (FR-013).
///
/// Writes are always queued locally first via [SyncQueue] (Principle IV —
/// completing a session must work offline) and pushed to Supabase
/// opportunistically; this repository exposes the "record a completion"
/// intent, independent of whether the push happens immediately or later.
class SessionLogRepository extends BaseRepository {
  SessionLogRepository({
    required super.supabase,
    required super.localDatabase,
    required this.syncQueueEnqueue,
  });

  /// Injected rather than depending on `SyncQueue` directly, so this
  /// repository's tests don't need a real offline queue/database.
  final Future<void> Function({
    required String clientId,
    required String sessionId,
    required SessionLogSourceMode sourceMode,
  }) syncQueueEnqueue;

  /// Logs that [clientId] completed [sessionId] via [sourceMode]
  /// (`daily_formula` for US1). Always succeeds from the caller's
  /// perspective — the actual network write happens via the offline queue.
  Future<void> logCompletion({
    required String clientId,
    required String sessionId,
    required SessionLogSourceMode sourceMode,
  }) {
    return syncQueueEnqueue(
      clientId: clientId,
      sessionId: sessionId,
      sourceMode: sourceMode,
    );
  }
}
