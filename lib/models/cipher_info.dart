/// Cipher Information Model for API Display
class CipherInfo {
  final int id;
  final String name;
  final String type;
  final String description;
  final String algorithm;
  final String complexity;
  final List<String> keyRequirements;

  CipherInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.algorithm,
    required this.complexity,
    required this.keyRequirements,
  });

  factory CipherInfo.fromJson(Map<String, dynamic> json) {
    return CipherInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      algorithm: json['algorithm'] as String,
      complexity: json['complexity'] as String,
      keyRequirements: List<String>.from(json['keyRequirements'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'algorithm': algorithm,
      'complexity': complexity,
      'keyRequirements': keyRequirements,
    };
  }
}
