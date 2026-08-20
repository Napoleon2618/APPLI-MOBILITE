import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/session_log.dart';
import 'local_database.dart';

/// Queues session completions recorded while offline and pushes them to
/// Supabase once connectivity returns (Principle IV).
///
/// Completing a session never blocks on network: [enqueue] always writes
/// locally first, then [syncPending] is called opportunistically (app
/// resume, connectivity regained) to flush anything not yet synced.
class SyncQueue {
  SyncQueue(this._db);

  final LocalDatabase _db;
  static const _uuid = Uuid();

  /// Records a session completion locally. Returns immediately; the caller
  /// does not need to be online.
  Future<void> enqueue({
    required String clientId,
    required String sessionId,
    required SessionLogSourceMode sourceMode,
  }) {
    return _db.into(_db.pendingSessionLog).insert(
          PendingSessionLogCompanion.insert(
            localId: _uuid.v4(),
            clientId: clientId,
            sessionId: sessionId,
            sourceMode: sourceMode.value,
            completedAt: DateTime.now(),
          ),
        );
  }

  /// Pushes every not-yet-synced entry to Supabase. Entries that fail to
  /// sync (e.g. still offline) are left queued and retried on the next call.
  Future<void> syncPending(SupabaseClient supabase) async {
    final pending = await (_db.select(_db.pendingSessionLog)
          ..where((t) => t.synced.equals(false)))
        .get();

    for (final entry in pending) {
      try {
        await supabase.from('session_log').insert({
          'client_id': entry.clientId,
          'session_id': entry.sessionId,
          'source_mode': entry.sourceMode,
          'completed_at': entry.completedAt.toIso8601String(),
        });
        await (_db.update(_db.pendingSessionLog)
              ..where((t) => t.localId.equals(entry.localId)))
            .write(const PendingSessionLogCompanion(synced: Value(true)));
      } on Object {
        // Still offline, or a transient failure: leave it queued, try again
        // on the next syncPending() call rather than surfacing an error to
        // the user mid-session (Principle IV — degrade gracefully).
        continue;
      }
    }
  }

  /// Number of completions not yet synced — used to show a subtle pending
  /// indicator if needed.
  Future<int> pendingCount() async {
    final rows = await (_db.select(_db.pendingSessionLog)
          ..where((t) => t.synced.equals(false)))
        .get();
    return rows.length;
  }
}
