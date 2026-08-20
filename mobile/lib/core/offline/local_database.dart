import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

/// Cached daily-formula/session content already fetched from Supabase, kept
/// so it stays readable offline (Principle IV).
class CachedDailyFormula extends Table {
  TextColumn get id => text()();
  TextColumn get coachId => text()();
  TextColumn get sessionId => text()();
  DateTimeColumn get date => dateTime()();

  /// JSON-encoded [SessionModel] (id/name/exercises), denormalized so a
  /// single row is enough to render the "today's session" screen offline.
  TextColumn get sessionJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A session completion recorded while offline, queued for sync once
/// connectivity returns (Principle IV, FR-013).
class PendingSessionLog extends Table {
  TextColumn get localId => text()();
  TextColumn get clientId => text()();
  TextColumn get sessionId => text()();
  TextColumn get sourceMode => text()();
  DateTimeColumn get completedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

@DriftDatabase(tables: [CachedDailyFormula, PendingSessionLog])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  /// For tests: an in-memory database that doesn't touch the filesystem.
  LocalDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'appli_mobilite.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
