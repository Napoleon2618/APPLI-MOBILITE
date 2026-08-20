import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/async_state_view.dart';
import '../../data/models/daily_formula.dart';
import '../../data/repositories/daily_formula_repository.dart';
import '../../data/repositories/session_log_repository.dart';
import '../auth/auth_state.dart';
import 'session_player_screen.dart';

/// US1 — home screen: shows today's ready-to-follow session with no
/// selection step (FR-001). Handles the "no daily formula for today"
/// fallback state explicitly (FR-015).
class DailyFormulaScreen extends StatefulWidget {
  /// [repository]/[coachId] and [sessionLogRepository]/[clientId] are
  /// normally resolved from Provider context (Supabase-backed repositories,
  /// the signed-in client and their coach); they can be overridden directly
  /// in tests, and are forwarded to the pushed [SessionPlayerScreen] so a
  /// whole flow can be driven end-to-end without a real Supabase session —
  /// see `test/widget/daily_formula_screen_test.dart` and
  /// `test/integration/daily_formula_flow_test.dart`.
  const DailyFormulaScreen({
    super.key,
    this.repository,
    this.coachId,
    this.sessionLogRepository,
    this.clientId,
  });

  final DailyFormulaRepository? repository;
  final String? coachId;
  final SessionLogRepository? sessionLogRepository;
  final String? clientId;

  @override
  State<DailyFormulaScreen> createState() => _DailyFormulaScreenState();
}

class _DailyFormulaScreenState extends State<DailyFormulaScreen> {
  late Future<DailyFormula?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DailyFormula?> _load() {
    final coachId = widget.coachId ?? context.read<AppAuthState>().coachScopeId!;
    final repository = widget.repository ?? context.read<DailyFormulaRepository>();
    return repository.getTodayFormula(coachId: coachId);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aujourd'hui")),
      body: AsyncStateView<DailyFormula?>(
        future: _future,
        emptyWhen: (formula) => formula == null,
        emptyBuilder: (context) => const _NoFormulaTodayState(),
        errorBuilder: (context, error) => ErrorState(error: error, onRetry: _refresh),
        builder: (context, formula) => _TodaySessionCard(
          formula: formula!,
          sessionLogRepository: widget.sessionLogRepository,
          clientId: widget.clientId,
        ),
      ),
    );
  }
}

class _NoFormulaTodayState extends StatelessWidget {
  const _NoFormulaTodayState();

  @override
  Widget build(BuildContext context) {
    // FR-015 edge case: no daily formula designated yet for today — an
    // explicit, friendly state rather than a blank/error screen.
    return const EmptyStateMessage(
      message: "Votre coach n'a pas encore programmé de séance pour "
          "aujourd'hui. Revenez un peu plus tard !",
    );
  }
}

class _TodaySessionCard extends StatelessWidget {
  const _TodaySessionCard({
    required this.formula,
    this.sessionLogRepository,
    this.clientId,
  });

  final DailyFormula formula;
  final SessionLogRepository? sessionLogRepository;
  final String? clientId;

  @override
  Widget build(BuildContext context) {
    final session = formula.session!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(session.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('${session.exercises.length} exercices'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SessionPlayerScreen(
                          session: session,
                          repository: sessionLogRepository,
                          clientId: clientId,
                        ),
                      ),
                    );
                  },
                  child: const Text('Commencer la séance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
