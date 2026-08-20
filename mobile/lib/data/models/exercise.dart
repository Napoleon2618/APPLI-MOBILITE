/// A mobility/stretching exercise created by a coach — see data-model.md.
///
/// [youtubeVideoUrl] points to a YouTube-hosted demonstration video; no
/// video file is stored in Supabase Storage (data-model.md, "Note —
/// hébergement vidéo").
class Exercise {
  const Exercise({
    required this.id,
    required this.coachId,
    required this.name,
    required this.description,
    required this.instructions,
    required this.createdAt,
    required this.updatedAt,
    this.youtubeVideoUrl,
    this.archivedAt,
  });

  final String id;
  final String coachId;
  final String name;
  final String description;
  final String instructions;
  final String? youtubeVideoUrl;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// FR-023: an archived exercise (deleted while referenced by a client's
  /// history) is excluded from active lists but stays visible in history.
  bool get isArchived => archivedAt != null;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        coachId: json['coach_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        instructions: json['instructions'] as String,
        youtubeVideoUrl: json['youtube_video_url'] as String?,
        archivedAt: json['archived_at'] == null
            ? null
            : DateTime.parse(json['archived_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
