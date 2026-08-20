import 'package:flutter/material.dart';

/// Wraps a [Future]-backed screen with explicit loading, error and (empty)
/// states, so every screen handles them the same way instead of each
/// re-inventing it or, worse, silently showing a blank screen — required by
/// Principle III ("Error states, loading states, and empty states MUST be
/// handled explicitly for every user-facing screen").
///
/// Usage:
/// ```dart
/// AsyncStateView<List<Exercise>>(
///   future: repository.listExercisesForZone(zoneId),
///   emptyWhen: (exercises) => exercises.isEmpty,
///   emptyBuilder: (context) => const EmptyStateMessage(
///     message: "Aucun exercice pour cette zone pour l'instant.",
///   ),
///   builder: (context, exercises) => ExerciseList(exercises: exercises),
/// )
/// ```
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.future,
    required this.builder,
    this.emptyWhen,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;

  /// If provided and returns true for the loaded data, [emptyBuilder] (or
  /// the default empty state) is shown instead of [builder].
  final bool Function(T data)? emptyWhen;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final WidgetBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ?? const LoadingState();
        }
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              ErrorState(error: snapshot.error!);
        }

        final data = snapshot.data as T;
        if (emptyWhen != null && emptyWhen!(data)) {
          return emptyBuilder?.call(context) ?? const EmptyStateMessage();
        }
        return builder(context, data);
      },
    );
  }
}

/// Default loading indicator, centered and unobtrusive.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Default error state: a clear message plus an optional retry action —
/// never a raw exception dump or a blank screen.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(
              'Une erreur est survenue. Réessayez dans un instant.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Explicit "no content" state (FR-015): used whenever a navigation mode
/// (daily formula, body zone, pain sign) has nothing to show, instead of an
/// empty, unexplained screen.
class EmptyStateMessage extends StatelessWidget {
  const EmptyStateMessage({
    super.key,
    this.message = "Rien à afficher pour l'instant.",
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
