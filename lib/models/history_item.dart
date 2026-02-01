/// History Item Model for Cipher Operations
class HistoryItem {
  final String id;
  final String cipherName; // "Caesar" or "Playfair"
  final String inputText;
  final String outputText;
  final String keyOrShift; // Shift value for Caesar, Key for Playfair
  final String operationType; // "Encrypt" or "Decrypt"
  final DateTime timestamp;
  
  HistoryItem({
    required this.id,
    required this.cipherName,
    required this.inputText,
    required this.outputText,
    required this.keyOrShift,
    required this.operationType,
    required this.timestamp,
  });
  
  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cipherName': cipherName,
      'inputText': inputText,
      'outputText': outputText,
      'keyOrShift': keyOrShift,
      'operationType': operationType,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  /// Create from Map
  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      cipherName: map['cipherName'],
      inputText: map['inputText'],
      outputText: map['outputText'],
      keyOrShift: map['keyOrShift'],
      operationType: map['operationType'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
