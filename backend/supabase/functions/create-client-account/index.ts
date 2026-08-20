// FR-022b: lets an authenticated coach create a client account directly
// (email + provisional password), without going through an invite code.
//
// A regular authenticated user cannot create another Supabase Auth
// identity from the mobile app — that requires the service-role key, which
// must never be embedded in the app (Principle V). This Edge Function is
// the only place that key is used: it verifies the caller is a coach using
// their own JWT, then uses the service-role key (available only in this
// function's server-side environment) to create the client's Auth
// identity and the corresponding `client` row.
//
// See data-model.md ("Note — deux parcours de rattachement") and
// contracts/auth.md for the full contract.

import { createClient } from 'npm:@supabase/supabase-js@2';

interface CreateClientAccountRequest {
  email?: string;
  provisionalPassword?: string;
  displayName?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method not allowed' }, 405);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse({ error: 'missing Authorization header' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse({ error: 'server misconfiguration' }, 500);
  }

  // Scoped to the caller's own JWT — used only to verify their identity and
  // role, never to perform the privileged creation below.
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await callerClient.auth.getUser();
  if (userError || !userData?.user) {
    return jsonResponse({ error: 'not authenticated' }, 401);
  }
  const callerId = userData.user.id;

  const { data: coachRow, error: coachError } = await callerClient
    .from('coach')
    .select('id')
    .eq('id', callerId)
    .maybeSingle();

  if (coachError) {
    return jsonResponse({ error: 'failed to verify coach role' }, 500);
  }
  if (!coachRow) {
    return jsonResponse({ error: 'only a coach can create a client account' }, 403);
  }

  let body: CreateClientAccountRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'invalid JSON body' }, 400);
  }

  const { email, provisionalPassword, displayName } = body;
  if (!email || !provisionalPassword) {
    return jsonResponse({ error: 'email and provisionalPassword are required' }, 400);
  }

  // Service-role key: only ever read from this function's own environment.
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: created, error: createError } = await adminClient.auth.admin.createUser({
    email,
    password: provisionalPassword,
    email_confirm: true,
  });

  if (createError || !created?.user) {
    return jsonResponse({ error: createError?.message ?? 'failed to create client account' }, 400);
  }

  const { error: insertError } = await adminClient.from('client').insert({
    id: created.user.id,
    coach_id: callerId,
    display_name: displayName ?? email,
  });

  if (insertError) {
    // Avoid leaving an orphaned Auth identity with no matching client row.
    await adminClient.auth.admin.deleteUser(created.user.id);
    return jsonResponse({ error: insertError.message }, 500);
  }

  return jsonResponse({ clientId: created.user.id, coachId: callerId }, 200);
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
