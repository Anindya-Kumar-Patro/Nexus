class Venture {
  final String id;
  final String ownerId;
  final String title;
  final String oneLiner;
  final String description;
  final String stage;
  final List<String> lookingFor;
  final String status; // Keep as String, we handle null in the factory

  Venture({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.oneLiner,
    required this.description,
    required this.stage,
    required this.lookingFor,
    this.status = 'active', 
  });

  factory Venture.fromJson(Map<String, dynamic> json) {
    return Venture(
      id: json['id'].toString(),
      ownerId: json['owner_id'] ?? '',
      title: json['title'] ?? '',
      oneLiner: json['one_liner'] ?? '',
      description: json['description'] ?? '',
      stage: json['stage'] ?? '',
      lookingFor: List<String>.from(json['looking_for'] ?? []),
      // FIX: Handle null by providing a default value
      status: (json['status'] as String?) ?? 'active', 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'title': title,
      'one_liner': oneLiner,
      'description': description,
      'stage': stage,
      'looking_for': lookingFor,
      'status': status,
    };
  }
}