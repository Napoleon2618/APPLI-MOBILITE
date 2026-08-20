import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_role.dart';

/// Tracks the current authenticated user, their role (coach vs client —
/// FR-010), and the coach scope relevant to them: their own id if they are
/// a coach, or their `client.coach_id` if they are a client.
///
/// The role is not stored on the Supabase Auth user itself; it is derived
/// by checking which of the `coach` / `client` tables has a row for
/// `auth.uid()` (see data-model.md — a user is exactly one or the other).
///
/// Named `AppAuthState` (not `AuthState`) to avoid clashing with
/// `supabase_flutter`'s own `AuthState` auth-event payload type.
class AppAuthState extends ChangeNotifier {
  AppAuthState(this._supabase) {
    _authSubscription = _supabase.auth.onAuthStateChange.listen(_onAuthChange);
    unawaited(_bootstrap());
  }

  final SupabaseClient _supabase;
  late final StreamSubscription<AuthState> _authSubscription;

  User? _user;
  UserRole? _role;
  String? _coachScopeId;
  bool _loading = true;

  User? get user => _user;
  UserRole? get role => _role;

  /// The coach whose content is relevant to this user: their own id if they
  /// are a coach, or their attached coach's id if they are a client.
  String? get coachScopeId => _coachScopeId;

  bool get isAuthenticated => _user != null;

  /// True while the initial session/role resolution is in flight — the
  /// router uses this to avoid redirecting before we actually know whether
  /// the user is authenticated (Principle III: no flash of the wrong state).
  bool get loading => _loading;

  Future<void> _bootstrap() async {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      await _resolveRole(_user!.id);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _onAuthChange(AuthState data) async {
    final session = data.session;
    _user = session?.user;
    if (_user != null) {
      await _resolveRole(_user!.id);
    } else {
      _role = null;
      _coachScopeId = null;
    }
    notifyListeners();
  }

  Future<void> _resolveRole(String userId) async {
    final coachRow = await _supabase
        .from('coach')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (coachRow != null) {
      _role = UserRole.coach;
      _coachScopeId = userId;
      return;
    }

    final clientRow = await _supabase
        .from('client')
        .select('coach_id')
        .eq('id', userId)
        .maybeSingle();

    if (clientRow != null) {
      _role = UserRole.client;
      _coachScopeId = clientRow['coach_id'] as String;
      return;
    }

    // Authenticated but not yet provisioned (e.g. mid-signup, before an
    // invite code has been redeemed): no role yet.
    _role = null;
    _coachScopeId = null;
  }

  Future<void> signOut() => _supabase.auth.signOut();

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
