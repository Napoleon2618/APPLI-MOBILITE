import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/daily_formula.dart';
import 'package:mobile/data/models/exercise.dart';
import 'package:mobile/data/models/session.dart';
import 'package:mobile/data/repositories/daily_formula_repository.dart';
import 'package:mobile/features/daily_formula/daily_formula_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockDailyFormulaRepository extends Mock implements DailyFormulaRepository {}

DailyFormula _formulaWith(List<Exercise> exercises) {
  final session = SessionModel(
    id: 's1',
    coachId: 'coach1',
    name: 'Réveil musculaire',
    createdAt: DateTime(2026, 1, 1),
    exercises: exercises,
  );
  return DailyFormula(
    id: 'f1',
    coachId: 'coach1',
    sessionId: 's1',
    date: DateTime(2026, 1, 1),
    session: session,
  );
}

Exercise _exercise(String id) => Exercise(
      id: id,
      coachId: 'coach1',
      name: 'Étirement $id',
      description: 'desc',
      instructions: 'instr',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('DailyFormulaScreen', () {
    testWidgets(
      "shows today's session with no selection step when a daily formula exists (FR-001)",
      (tester) async {
        final repository = _MockDailyFormulaRepository();
        when(() => repository.getTodayFormula(coachId: 'coach1'))
            .thenAnswer((_) async => _formulaWith([_exercise('e1'), _exercise('e2')]));

        await tester.pumpWidget(
          MaterialApp(
            home: DailyFormulaScreen(repository: repository, coachId: 'coach1'),
          ),
        );
        await tester.pumpAndSettle();

        // The session is shown directly — no zone/sign selection widget of
        // any kind is present, only a single "start" action.
        expect(find.text('Réveil musculaire'), findsOneWidget);
        expect(find.text('2 exercices'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Commencer la séance'), findsOneWidget);
      },
    );

    testWidgets(
      'shows an explicit empty state when no daily formula exists for today (FR-015)',
      (tester) async {
        final repository = _MockDailyFormulaRepository();
        when(() => repository.getTodayFormula(coachId: 'coach1'))
            .thenAnswer((_) async => null);

        await tester.pumpWidget(
          MaterialApp(
            home: DailyFormulaScreen(repository: repository, coachId: 'coach1'),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining("n'a pas encore programmé"),
          findsOneWidget,
        );
        // Not a blank screen: no crash, no leftover loading spinner.
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('shows an explicit error state (with retry) if the fetch fails', (tester) async {
      final repository = _MockDailyFormulaRepository();
      when(() => repository.getTodayFormula(coachId: 'coach1'))
          .thenAnswer((_) async => throw Exception('network down'));

      await tester.pumpWidget(
        MaterialApp(
          home: DailyFormulaScreen(repository: repository, coachId: 'coach1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Une erreur est survenue'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Réessayer'), findsOneWidget);
    });
  });
}
