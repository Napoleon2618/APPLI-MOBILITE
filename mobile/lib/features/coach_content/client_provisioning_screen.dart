import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Coach-direct client account creation (FR-022b): the coach provides an
/// email and a provisional password, and the app calls the
/// `create-client-account` Edge Function (which alone holds the
/// service-role key needed to create another user's Auth identity —
/// Principle V). See `backend/supabase/functions/create-client-account/`.
class ClientProvisioningScreen extends StatefulWidget {
  const ClientProvisioningScreen({super.key});

  @override
  State<ClientProvisioningScreen> createState() => _ClientProvisioningScreenState();
}

class _ClientProvisioningScreenState extends State<ClientProvisioningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-client-account',
        body: {
          'email': _emailController.text.trim(),
          'provisionalPassword': _passwordController.text,
          if (_nameController.text.trim().isNotEmpty) 'displayName': _nameController.text.trim(),
        },
      );

      if (response.status != 200) {
        final error = (response.data is Map) ? response.data['error'] : null;
        setState(() => _errorMessage = error?.toString() ?? 'Échec de la création du compte.');
        return;
      }

      setState(() {
        _successMessage =
            'Compte créé pour ${_emailController.text.trim()}. '
            'Communiquez le mot de passe provisoire au client.';
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
      });
    } catch (_) {
      setState(() => _errorMessage = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte client')),
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nom (optionnel)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email du client'),
                      validator: (value) =>
                          (value == null || !value.contains('@')) ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mot de passe provisoire'),
                      validator: (value) => (value == null || value.length < 8)
                          ? 'Au moins 8 caractères'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    if (_successMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_successMessage!),
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
                          : const Text('Créer le compte'),
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
