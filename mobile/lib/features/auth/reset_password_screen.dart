import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Password reset (FR-020, SC-007): request an email, then (once the user
/// follows the link and returns to the app with a recovery session) choose
/// a new password. Both steps live on this one screen, switching view based
/// on whether a recovery session is currently active.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _requestFormKey = GlobalKey<FormState>();
  final _newPasswordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _submitting = false;
  bool _requestSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  bool get _hasRecoverySession =>
      Supabase.instance.client.auth.currentSession != null;

  Future<void> _requestReset() async {
    if (!(_requestFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );
      // Always show the same confirmation, whether or not the address is
      // registered — least-disclosure principle (contracts/auth.md).
      setState(() => _requestSent = true);
    } catch (_) {
      setState(() => _requestSent = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _setNewPassword() async {
    if (!(_newPasswordFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe mis à jour.')),
        );
      }
    } catch (_) {
      setState(() => _errorMessage = 'Impossible de mettre à jour le mot de passe.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
              child: _hasRecoverySession ? _buildNewPasswordForm(context) : _buildRequestForm(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm(BuildContext context) {
    if (_requestSent) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.mark_email_read_outlined, size: 40),
          SizedBox(height: 12),
          Text(
            'Si un compte existe pour cet email, un lien de réinitialisation '
            'vient de lui être envoyé.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Form(
      key: _requestFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mot de passe oublié', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) =>
                (value == null || !value.contains('@')) ? 'Email invalide' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _requestReset,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Recevoir le lien'),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordForm(BuildContext context) {
    return Form(
      key: _newPasswordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouveau mot de passe', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextFormField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
            validator: (value) =>
                (value == null || value.length < 8) ? 'Au moins 8 caractères' : null,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _setNewPassword,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}
