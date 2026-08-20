import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/data/models/user_role.dart';

// Tests the routing guard's pure decision logic (`computeRedirect`) rather
// than a full widget tree, so the auth/role gating contract can be verified
// without standing up a real (or mocked) Supabase session — see the
// doc comment on `computeRedirect` in app_router.dart.
void main() {
  group('computeRedirect', () {
    test('an unauthenticated user is redirected to /login', () {
      final result = computeRedirect(
        loading: false,
        isAuthenticated: false,
        role: null,
        matchedLocation: AppRoutes.home,
      );

      expect(result, AppRoutes.login);
    });

    test('an unauthenticated user already on an auth route is not redirected', () {
      for (final route in [AppRoutes.login, AppRoutes.signup, AppRoutes.resetPassword]) {
        final result = computeRedirect(
          loading: false,
          isAuthenticated: false,
          role: null,
          matchedLocation: route,
        );
        expect(result, isNull, reason: 'should not redirect away from $route');
      }
    });

    test('while loading, no redirect happens even if unauthenticated', () {
      final result = computeRedirect(
        loading: true,
        isAuthenticated: false,
        role: null,
        matchedLocation: AppRoutes.home,
      );

      expect(result, isNull);
    });

    test('an authenticated user on the login screen is sent home', () {
      final result = computeRedirect(
        loading: false,
        isAuthenticated: true,
        role: UserRole.client,
        matchedLocation: AppRoutes.login,
      );

      expect(result, AppRoutes.home);
    });

    test('a client is redirected away from coach-only routes (FR-010)', () {
      for (final route in [AppRoutes.coachCreateClient, AppRoutes.coachInviteCode]) {
        final result = computeRedirect(
          loading: false,
          isAuthenticated: true,
          role: UserRole.client,
          matchedLocation: route,
        );
        expect(result, AppRoutes.home, reason: '$route must be blocked for a client');
      }
    });

    test('a coach can reach coach-only routes', () {
      for (final route in [AppRoutes.coachCreateClient, AppRoutes.coachInviteCode]) {
        final result = computeRedirect(
          loading: false,
          isAuthenticated: true,
          role: UserRole.coach,
          matchedLocation: route,
        );
        expect(result, isNull, reason: '$route must be reachable for a coach');
      }
    });

    test('an authenticated user with no role yet stays on home (not redirected in a loop)', () {
      final result = computeRedirect(
        loading: false,
        isAuthenticated: true,
        role: null,
        matchedLocation: AppRoutes.home,
      );

      expect(result, isNull);
    });
  });
}
