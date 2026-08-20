import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client self-signup via a coach-issued invite code (FR-022a).
///
/// Two steps, matching the server-side design in
/// `backend/supabase/migrations/0018_fn_redeem_invite_code.sql`:
/// 1. Create the Supabase Auth identity (email + password) — a normal,
///    unauthenticated `signUp` call.
/// 2. Once the resulting session is active, call the `redeem_invite_code`
///    RPC to validate the code and attach the new client to the right
///    coach. If step 2 fails (invalid/used code), the Auth identity from
///    step 1 already exists but no `client` row does — the UI surfaces
///    this clearly and lets the person retry with a different code
///    (contracts/auth.md).
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final supabase = Supabase.instance.client;

    try {
      if (supabase.auth.currentSession == null) {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      await supabase.rpc(
        'redeem_invite_code',
        params: {'p_code': _codeController.text.trim()},
      );
      // Navigation happens automatically via the router once AppAuthState
      // re-resolves the (now-provisioned) role.
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = _friendlyRedeemError(e.message));
    } on AuthException {
      setState(() => _errorMessage = 'Impossible de créer ce compte. Vérifiez vos informations.');
    } catch (_) {
      setState(() => _errorMessage = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyRedeemError(String raw) {
    if (raw.contains('invalid invite code')) {
      return 'Ce code d\'invitation est invalide.';
    }
    if (raw.contains('already used')) {
      return 'Ce code d\'invitation a déjà été utilisé.';
    }
    if (raw.contains('already attached')) {
      return 'Ce compte est déjà rattaché à un coach.';
    }
    return 'Impossible de valider ce code. Vérifiez-le et réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Rejoindre votre coach', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    const Text("Utilisez le code d'invitation fourni par votre coach."),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          (value == null || !value.contains('@')) ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                      validator: (value) => (value == null || value.length < 8)
                          ? 'Au moins 8 caractères'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: "Code d'invitation"),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Code requis' : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Rejoindre'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
