import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Exercises the two client-provisioning paths (FR-022) against a real local
// Supabase stack, mirroring quickstart.md Scenario 6bis:
//   (a) invite-code self-signup → `redeem_invite_code` RPC
//   (b) coach-direct creation → `create-client-account` Edge Function
//
// Unlike the daily-formula flow tests, these two screens (SignupScreen,
// ClientProvisioningScreen) call `Supabase.instance.client` directly rather
// than through an injectable repository, and the behavior under test is the
// server-side RPC/Edge Function contract itself (validated at the SQL level
// in backend/supabase/tests/rls_isolation_test.sql and via `deno check` on
// the function) — so this test talks to Supabase directly rather than
// mocking it, the same way the RLS SQL tests do.
//
// Requires a running local Supabase stack (`supabase start` in
// backend/supabase/, with migrations + seed applied) and is skipped
// otherwise; Docker is unavailable in the sandbox this was authored in, so
// it could not be executed there — see the session notes / PR description.
// Run locally or in CI with Docker available:
//   SUPABASE_TEST_URL=http://127.0.0.1:54321 \
//   SUPABASE_TEST_ANON_KEY=<anon key from `supabase start`> \
//   flutter test test/integration/coach_client_provisioning_test.dart
void main() {
  const url = String.fromEnvironment('SUPABASE_TEST_URL');
  const anonKey = String.fromEnvironment('SUPABASE_TEST_ANON_KEY');
  final skip = url.isEmpty || anonKey.isEmpty;

  group('Client provisioning (FR-022)', () {
    late SupabaseClient supabase;

    setUpAll(() async {
      if (skip) return;
      supabase = SupabaseClient(url, anonKey);
    });

    test(
      'a coach-generated invite code can be redeemed by a new client, '
      'attaching them to the right coach',
      () async {
        // 1) Sign in as the seeded demo coach and generate a code.
        await supabase.auth.signInWithPassword(
          email: 'coach1@example.com',
          password: 'CoachPass123!',
        );
        final coachId = supabase.auth.currentUser!.id;
        final code = 'TEST-${DateTime.now().millisecondsSinceEpoch}';
        await supabase.from('invite_code').insert({'coach_id': coachId, 'code': code});
        await supabase.auth.signOut();

        // 2) A brand-new user signs up and redeems the code.
        final newEmail = 'newclient+${DateTime.now().millisecondsSinceEpoch}@example.com';
        await supabase.auth.signUp(email: newEmail, password: 'ClientPass123!');
        final redeemedCoachId = await supabase.rpc(
          'redeem_invite_code',
          params: {'p_code': code},
        );

        expect(redeemedCoachId, coachId);

        final clientRow = await supabase
            .from('client')
            .select('coach_id')
            .eq('id', supabase.auth.currentUser!.id)
            .single();
        expect(clientRow['coach_id'], coachId);
      },
      skip: skip ? 'requires SUPABASE_TEST_URL/SUPABASE_TEST_ANON_KEY (local Supabase)' : false,
    );

    test(
      'a coach can create a client account directly via the Edge Function',
      () async {
        await supabase.auth.signInWithPassword(
          email: 'coach1@example.com',
          password: 'CoachPass123!',
        );
        final coachId = supabase.auth.currentUser!.id;

        final newEmail = 'direct+${DateTime.now().millisecondsSinceEpoch}@example.com';
        final response = await supabase.functions.invoke(
          'create-client-account',
          body: {'email': newEmail, 'provisionalPassword': 'Provisional123!'},
        );

        expect(response.status, 200);
        final data = response.data as Map;
        expect(data['coachId'], coachId);

        final clientRow = await supabase
            .from('client')
            .select('coach_id')
            .eq('id', data['clientId'])
            .single();
        expect(clientRow['coach_id'], coachId);
      },
      skip: skip ? 'requires SUPABASE_TEST_URL/SUPABASE_TEST_ANON_KEY (local Supabase)' : false,
    );
  });
}
