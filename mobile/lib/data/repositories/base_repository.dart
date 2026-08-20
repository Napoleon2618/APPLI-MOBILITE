import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/offline/local_database.dart';

/// Shared dependencies for every repository: the Supabase client (remote
/// source of truth) and the local cache (Principle IV — content already
/// fetched stays readable offline).
///
/// Concrete repositories extend this and add entity-specific queries; the
/// offline fallback pattern (try remote, fall back to cache on failure) is
/// implemented per-repository where it matters (e.g.
/// `DailyFormulaRepository`), since what's worth caching differs by entity.
abstract class BaseRepository {
  BaseRepository({required this.supabase, required this.localDatabase});

  final SupabaseClient supabase;
  final LocalDatabase localDatabase;
}
