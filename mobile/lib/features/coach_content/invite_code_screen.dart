import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Coach-side invite-code generation (FR-022a): creates an `invite_code`
/// row scoped to the coach (enforced by RLS —
/// `backend/supabase/migrations/0017_rls_invite_code.sql`) and shows it so
/// the coach can share it with a prospective client.
class InviteCodeScreen extends StatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  bool _generating = false;
  String? _errorMessage;
  String? _generatedCode;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final code = _randomCode();

      await Supabase.instance.client.from('invite_code').insert({
        'coach_id': userId,
        'code': code,
      });

      setState(() => _generatedCode = code);
    } catch (_) {
      setState(() => _errorMessage = 'Impossible de générer un code. Réessayez.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _randomCode() {
    // Short, shareable code — not a full UUID (which would be unwieldy to
    // read aloud or type), but still effectively unique for this scale.
    return const Uuid().v4().substring(0, 8).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Code d'invitation")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_generatedCode != null) ...[
                Text(
                  _generatedCode!,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Partagez ce code avec votre client : il le saisira lors de son inscription.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _generating ? null : _generate,
                child: _generating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_generatedCode == null ? 'Générer un code' : 'Générer un nouveau code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
