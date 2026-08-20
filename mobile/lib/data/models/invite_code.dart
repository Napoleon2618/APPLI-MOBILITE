/// A coach-generated invite code (FR-022a) — see data-model.md.
class InviteCode {
  const InviteCode({
    required this.id,
    required this.coachId,
    required this.code,
    required this.createdAt,
    this.usedAt,
    this.usedByClientId,
  });

  final String id;
  final String coachId;
  final String code;
  final DateTime createdAt;
  final DateTime? usedAt;
  final String? usedByClientId;

  bool get isUsed => usedAt != null;

  factory InviteCode.fromJson(Map<String, dynamic> json) => InviteCode(
        id: json['id'] as String,
        coachId: json['coach_id'] as String,
        code: json['code'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        usedAt: json['used_at'] == null
            ? null
            : DateTime.parse(json['used_at'] as String),
        usedByClientId: json['used_by_client_id'] as String?,
      );
}
