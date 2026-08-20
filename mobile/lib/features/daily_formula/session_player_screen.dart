import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/session.dart';
import '../../data/models/session_log.dart';
import '../../data/repositories/session_log_repository.dart';
import '../auth/auth_state.dart';
import 'session_complete_view.dart';

/// Steps through a session's ordered exercises one at a time (US1
/// acceptance scenario 2). Reused later by the zone/pain-sign navigation
/// modes (US3/US4), which is why it takes a plain [SessionModel] rather
/// than anything daily-formula-specific.
class SessionPlayerScreen extends StatefulWidget {
  /// [repository] and [clientId] are normally resolved from Provider
  /// context; they can be overridden directly in tests without needing a
  /// real Supabase session — see
  /// `test/integration/daily_formula_flow_test.dart`.
  const SessionPlayerScreen({
    super.key,
    required this.session,
    this.sourceMode = SessionLogSourceMode.dailyFormula,
    this.repository,
    this.clientId,
  });

  final SessionModel session;
  final SessionLogSourceMode sourceMode;
  final SessionLogRepository? repository;
  final String? clientId;

  @override
  State<SessionPlayerScreen> createState() => _SessionPlayerScreenState();
}

class _SessionPlayerScreenState extends State<SessionPlayerScreen> {
  int _index = 0;
  bool _completing = false;

  bool get _isLast => _index == widget.session.exercises.length - 1;

  Future<void> _next() async {
    if (!_isLast) {
      setState(() => _index += 1);
      return;
    }
    await _completeSession();
  }

  Future<void> _completeSession() async {
    setState(() => _completing = true);

    final clientId = widget.clientId ?? context.read<AppAuthState>().user!.id;
    final repository = widget.repository ?? context.read<SessionLogRepository>();

    await repository.logCompletion(
      clientId: clientId,
      sessionId: widget.session.id,
      sourceMode: widget.sourceMode,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SessionCompleteView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.session.exercises;
    final exercise = exercises[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_index + 1) / exercises.length,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Exercice ${_index + 1}/${exercises.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(exercise.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.description),
                      const SizedBox(height: 12),
                      Text(exercise.instructions),
                      if (exercise.youtubeVideoUrl != null) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse(exercise.youtubeVideoUrl!)),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Voir la vidéo'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _completing ? null : _next,
                child: _completing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isLast ? 'Terminer la séance' : 'Exercice suivant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
