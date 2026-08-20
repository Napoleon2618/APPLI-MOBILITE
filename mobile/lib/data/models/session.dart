import 'exercise.dart';

/// An ordered set of exercises created by a coach — see data-model.md.
class SessionModel {
  const SessionModel({
    required this.id,
    required this.coachId,
    required this.name,
    required this.createdAt,
    this.exercises = const [],
  });

  final String id;
  final String coachId;
  final String name;
  final DateTime createdAt;

  /// Ordered exercises (via `session_exercise.position`), when loaded.
  final List<Exercise> exercises;

  factory SessionModel.fromJson(
    Map<String, dynamic> json, {
    List<Exercise> exercises = const [],
  }) =>
      SessionModel(
        id: json['id'] as String,
        coachId: json['coach_id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        exercises: exercises,
      );

  SessionModel copyWith({List<Exercise>? exercises}) => SessionModel(
        id: id,
        coachId: coachId,
        name: name,
        createdAt: createdAt,
        exercises: exercises ?? this.exercises,
      );
}
