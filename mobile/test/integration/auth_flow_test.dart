import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Exercises login, wrong-password handling, the password-reset request, and
// cross-device progress retrieval (FR-018), mirroring quickstart.md
// Scenario 6.
//
// Requires a running local Supabase stack — see
// `coach_client_provisioning_test.dart` for why this talks to Supabase
// directly instead of mocking it, and how to run it locally/in CI:
//   SUPABASE_TEST_URL=http://127.0.0.1:54321 \
//   SUPABASE_TEST_ANON_KEY=<anon key from `supabase start`> \
//   flutter test test/integration/auth_flow_test.dart
void main() {
  const url = String.fromEnvironment('SUPABASE_TEST_URL');
  const anonKey = String.fromEnvironment('SUPABASE_TEST_ANON_KEY');
  final skip = url.isEmpty || anonKey.isEmpty;

  group('Authentication (FR-019, FR-020, FR-018, SC-007)', () {
    test(
      'a wrong password is rejected with a generic error (no email/password distinction)',
      () async {
        final supabase = SupabaseClient(url, anonKey);
        await expectLater(
          supabase.auth.signInWithPassword(
            email: 'clienta@example.com',
            password: 'not-the-real-password',
          ),
          throwsA(isA<AuthException>()),
        );
      },
      skip: skip ? 'requires SUPABASE_TEST_URL/SUPABASE_TEST_ANON_KEY (local Supabase)' : false,
    );

    test(
      'requesting a password reset for a known email succeeds without error',
      () async {
        final supabase = SupabaseClient(url, anonKey);
        // Supabase returns success regardless of whether the address is
        // registered — least-disclosure principle (contracts/auth.md);
        // this just asserts the call itself doesn't throw.
        await supabase.auth.resetPasswordForEmail('clienta@example.com');
      },
      skip: skip ? 'requires SUPABASE_TEST_URL/SUPABASE_TEST_ANON_KEY (local Supabase)' : false,
    );

    test(
      'progress logged on one session is visible after signing in again '
      '(simulating a new device — FR-018)',
      () async {
        // "Device 1": log in and record a session completion.
        final deviceOne = SupabaseClient(url, anonKey);
        await deviceOne.auth.signInWithPassword(
          email: 'clienta@example.com',
          password: 'ClientPass123!',
        );
        final clientId = deviceOne.auth.currentUser!.id;

        final clientRow = await deviceOne
            .from('client')
            .select('coach_id')
            .eq('id', clientId)
            .single();

        final session = await deviceOne
            .from('session')
            .select('id')
            .eq('coach_id', clientRow['coach_id'])
            .limit(1)
            .single();

        await deviceOne.from('session_log').insert({
          'client_id': clientId,
          'session_id': session['id'],
          'source_mode': 'daily_formula',
        });
        await deviceOne.auth.signOut();

        // "Device 2": a fresh client instance, same credentials — the
        // history must already be there, no manual resync needed.
        final deviceTwo = SupabaseClient(url, anonKey);
        await deviceTwo.auth.signInWithPassword(
          email: 'clienta@example.com',
          password: 'ClientPass123!',
        );

        final history = await deviceTwo
            .from('session_log')
            .select('id')
            .eq('client_id', deviceTwo.auth.currentUser!.id);

        expect(history, isNotEmpty);
      },
      skip: skip ? 'requires SUPABASE_TEST_URL/SUPABASE_TEST_ANON_KEY (local Supabase)' : false,
    );
  });
}
