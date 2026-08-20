import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_role.dart';
import '../../features/auth/auth_state.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/coach_content/client_provisioning_screen.dart';
import '../../features/coach_content/invite_code_screen.dart';
import '../../features/daily_formula/daily_formula_screen.dart';

/// Route paths, centralized so screens don't hardcode route strings.
abstract final class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';
  static const resetPassword = '/reset-password';
  static const home = '/';
  static const coachCreateClient = '/coach/create-client';
  static const coachInviteCode = '/coach/invite-code';
}

/// Builds the app's [GoRouter], gating every route behind authentication
/// and, for `/`, behind the resolved role (FR-010: a client never reaches
/// coach-only screens).
GoRouter buildAppRouter(AppAuthState authState) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authState,
    redirect: (context, state) => computeRedirect(
      loading: authState.loading,
      isAuthenticated: authState.isAuthenticated,
      role: authState.role,
      matchedLocation: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _HomeGate(),
      ),
      GoRoute(
        path: AppRoutes.coachCreateClient,
        builder: (context, state) => const ClientProvisioningScreen(),
      ),
      GoRoute(
        path: AppRoutes.coachInviteCode,
        builder: (context, state) => const InviteCodeScreen(),
      ),
    ],
  );
}

/// Pure routing-guard logic (FR-010, FR-019), deliberately decoupled from
/// [AppAuthState]/`GoRouterState` so it can be unit-tested directly without
/// mocking Supabase or the widget tree — see
/// `test/widget/auth_routing_test.dart`.
String? computeRedirect({
  required bool loading,
  required bool isAuthenticated,
  required UserRole? role,
  required String matchedLocation,
}) {
  if (loading) {
    // Session/role resolution still in flight: don't redirect yet, avoids a
    // flash of the login screen for an already-authenticated user.
    return null;
  }

  final onAuthRoute = matchedLocation == AppRoutes.login ||
      matchedLocation == AppRoutes.signup ||
      matchedLocation == AppRoutes.resetPassword;

  if (!isAuthenticated) {
    return onAuthRoute ? null : AppRoutes.login;
  }

  // Authenticated: never let an authenticated user sit on the auth screens.
  if (onAuthRoute) {
    return AppRoutes.home;
  }

  // FR-010: a client must never reach coach-only routes.
  final isCoachRoute = matchedLocation == AppRoutes.coachCreateClient ||
      matchedLocation == AppRoutes.coachInviteCode;
  if (isCoachRoute && role != UserRole.coach) {
    return AppRoutes.home;
  }

  return null;
}

/// `/` resolves to a different screen depending on role. For a coach, the
/// full content dashboard is out of scope for this increment (see US2 /
/// T064); this is a minimal, explicitly temporary entry point to the two
/// Foundational-scope provisioning screens (T042, T043).
class _HomeGate extends StatelessWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppAuthState>().role;

    if (role == UserRole.client) {
      return const DailyFormulaScreen();
    }

    if (role == UserRole.coach) {
      return const _CoachProvisioningHub();
    }

    // Authenticated but not yet provisioned (e.g. invite code not redeemed
    // yet): keep this minimal and explicit rather than a blank screen.
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Votre compte n'est pas encore rattaché à un coach. "
            'Contactez votre coach pour obtenir un code d\'invitation.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CoachProvisioningHub extends StatelessWidget {
  const _CoachProvisioningHub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace coach')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.coachInviteCode),
              child: const Text("Générer un code d'invitation"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.coachCreateClient),
              child: const Text('Créer un compte client'),
            ),
          ],
        ),
      ),
    );
  }
}
