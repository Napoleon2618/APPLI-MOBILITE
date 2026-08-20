import 'dart:convert';

import '../../core/offline/local_database.dart';
import '../models/daily_formula.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import 'base_repository.dart';

/// Fetches today's daily formula (FR-001) for a client's coach, with the
/// session's ordered exercises resolved.
///
/// Principle IV: if the remote fetch fails (offline), the last successfully
/// fetched daily formula for this coach is served from the local cache
/// instead of failing outright.
class DailyFormulaRepository extends BaseRepository {
  DailyFormulaRepository({required super.supabase, required super.localDatabase});

  /// Returns today's daily formula for [coachId], or `null` if the coach
  /// hasn't designated one for today (FR-015 — the screen shows an explicit
  /// fallback state for this, it is not an error).
  Future<DailyFormula?> getTodayFormula({required String coachId}) async {
    final today = DateTime.now();

    try {
      final formulaRow = await supabase
          .from('daily_formula')
          .select('id, coach_id, session_id, date')
          .eq('coach_id', coachId)
          .eq('date', _isoDate(today))
          .maybeSingle();

      if (formulaRow == null) {
        return null;
      }

      final sessionId = formulaRow['session_id'] as String;

      final sessionRow = await supabase
          .from('session')
          .select('id, coach_id, name, created_at')
          .eq('id', sessionId)
          .single();

      final exerciseRows = await supabase
          .from('session_exercise')
          .select('position, exercise:exercise_id(*)')
          .eq('session_id', sessionId)
          .order('position');

      final exercises = (exerciseRows as List)
          .map(
            (row) => Exercise.fromJson(
              (row as Map<String, dynamic>)['exercise'] as Map<String, dynamic>,
            ),
          )
          .toList();

      final session = SessionModel.fromJson(sessionRow, exercises: exercises);
      final formula = DailyFormula.fromJson(formulaRow, session: session);

      await _cache(coachId, formula);
      return formula;
    } catch (_) {
      return _readCache(coachId, today);
    }
  }

  Future<void> _cache(String coachId, DailyFormula formula) async {
    final session = formula.session;
    if (session == null) return;

    await localDatabase.into(localDatabase.cachedDailyFormula).insertOnConflictUpdate(
          CachedDailyFormulaCompanion.insert(
            id: coachId, // one cached "today" entry per coach is enough
            coachId: coachId,
            sessionId: formula.sessionId,
            date: formula.date,
            sessionJson: jsonEncode({
              'id': session.id,
              'name': session.name,
              'exercises': session.exercises
                  .map(
                    (e) => {
                      'id': e.id,
                      'name': e.name,
                      'description': e.description,
                      'instructions': e.instructions,
                      'youtube_video_url': e.youtubeVideoUrl,
                    },
                  )
                  .toList(),
            }),
            cachedAt: DateTime.now(),
          ),
        );
  }

  Future<DailyFormula?> _readCache(String coachId, DateTime today) async {
    final row = await (localDatabase.select(localDatabase.cachedDailyFormula)
          ..where((t) => t.id.equals(coachId)))
        .getSingleOrNull();

    if (row == null) return null;
    // A cached formula is only meaningful for the day it was cached for —
    // don't resurface yesterday's session as if it were today's.
    if (!_isSameDate(row.date, today)) return null;

    final decoded = jsonDecode(row.sessionJson) as Map<String, dynamic>;
    final exercises = (decoded['exercises'] as List)
        .map(
          (e) => Exercise(
            id: e['id'] as String,
            coachId: coachId,
            name: e['name'] as String,
            description: e['description'] as String,
            instructions: e['instructions'] as String,
            youtubeVideoUrl: e['youtube_video_url'] as String?,
            createdAt: row.cachedAt,
            updatedAt: row.cachedAt,
          ),
        )
        .toList();

    return DailyFormula(
      id: row.id,
      coachId: coachId,
      sessionId: row.sessionId,
      date: row.date,
      session: SessionModel(
        id: decoded['id'] as String,
        coachId: coachId,
        name: decoded['name'] as String,
        createdAt: row.cachedAt,
        exercises: exercises,
      ),
    );
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
