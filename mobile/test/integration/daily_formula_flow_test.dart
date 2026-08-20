import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/daily_formula.dart';
import 'package:mobile/data/models/exercise.dart';
import 'package:mobile/data/models/session.dart';
import 'package:mobile/data/models/session_log.dart';
import 'package:mobile/data/repositories/daily_formula_repository.dart';
import 'package:mobile/data/repositories/session_log_repository.dart';
import 'package:mobile/features/daily_formula/daily_formula_screen.dart';
import 'package:mobile/features/daily_formula/session_complete_view.dart';
import 'package:mocktail/mocktail.dart';

// End-to-end US1 flow (quickstart.md Scenario 1), driven through the
// `flutter test` widget harness with mocked repositories rather than the
// `integration_test` package + a real device/emulator — neither is
// available in this environment. This still exercises the real screens and
// real navigation between them, unlike a pure unit test; on-device
// validation of the same scenario remains covered by quickstart.md
// Scenario 1 for a run with a device attached.

class _MockDailyFormulaRepository extends Mock implements DailyFormulaRepository {}

class _MockSessionLogRepository extends Mock implements SessionLogRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(SessionLogSourceMode.dailyFormula);
  });

  testWidgets(
    'a client opens the app, sees today\'s session with zero selection steps, '
    'plays through every exercise, and reaches the completion confirmation',
    (tester) async {
      final dailyFormulaRepo = _MockDailyFormulaRepository();
      final sessionLogRepo = _MockSessionLogRepository();

      final exercises = [
        Exercise(
          id: 'e1',
          coachId: 'coach1',
          name: 'Étirement du chat-vache',
          description: 'Mobilise la colonne',
          instructions: 'À quatre pattes, alternez dos rond et dos creux.',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        Exercise(
          id: 'e2',
          coachId: 'coach1',
          name: "Cercles d'épaules",
          description: 'Détend les épaules',
          instructions: '10 cercles vers l\'avant, 10 vers l\'arrière.',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      final session = SessionModel(
        id: 's1',
        coachId: 'coach1',
        name: 'Réveil musculaire du matin',
        createdAt: DateTime(2026, 1, 1),
        exercises: exercises,
      );

      when(() => dailyFormulaRepo.getTodayFormula(coachId: 'coach1')).thenAnswer(
        (_) async => DailyFormula(
          id: 'f1',
          coachId: 'coach1',
          sessionId: 's1',
          date: DateTime(2026, 1, 1),
          session: session,
        ),
      );
      when(
        () => sessionLogRepo.logCompletion(
          clientId: any(named: 'clientId'),
          sessionId: any(named: 'sessionId'),
          sourceMode: any(named: 'sourceMode'),
        ),
      ).thenAnswer((_) async {});

      final stopwatch = Stopwatch()..start();

      // Step 1: home screen shows today's session directly — no selection.
      // The mocked SessionLogRepository/clientId are forwarded by
      // DailyFormulaScreen to the SessionPlayerScreen it pushes, so the
      // whole flow runs in a single widget tree, exactly as in the real app
      // (just with Supabase-backed repositories swapped for mocks).
      await tester.pumpWidget(
        MaterialApp(
          home: DailyFormulaScreen(
            repository: dailyFormulaRepo,
            coachId: 'coach1',
            sessionLogRepository: sessionLogRepo,
            clientId: 'client-a',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Réveil musculaire du matin'), findsOneWidget);
      final startButton = find.widgetWithText(ElevatedButton, 'Commencer la séance');
      expect(startButton, findsOneWidget);

      // Weak proxy for SC-001 (<10s to a startable session) within this
      // harness — real device/network timing is out of scope for a widget
      // test, this only guards against gross regressions (e.g. an
      // accidental blocking call added to the loading path).
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));

      // Step 2: start the session.
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.text('Étirement du chat-vache'), findsOneWidget);
      expect(find.text('Exercice 1/2'), findsOneWidget);

      // Step 3: step through every exercise.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Exercice suivant'));
      await tester.pumpAndSettle();
      expect(find.text("Cercles d'épaules"), findsOneWidget);
      expect(find.text('Exercice 2/2'), findsOneWidget);

      // Step 4: complete the session.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Terminer la séance'));
      await tester.pumpAndSettle();

      expect(find.byType(SessionCompleteView), findsOneWidget);
      expect(find.text('Séance terminée !'), findsOneWidget);

      verify(
        () => sessionLogRepo.logCompletion(
          clientId: 'client-a',
          sessionId: 's1',
          sourceMode: SessionLogSourceMode.dailyFormula,
        ),
      ).called(1);
    },
  );
}
