import 'package:flutter/material.dart';

/// Confirmation shown once every exercise in a session has been completed
/// (US1 acceptance scenario 2).
class SessionCompleteView extends StatelessWidget {
  const SessionCompleteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Séance terminée !', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Bravo, à demain pour une nouvelle séance.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
