import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore History Item Model
class FirestoreHistoryItem {
  final String? id; // Document ID from Firestore
  final String cipherType; // "Caesar" or "Playfair"
  final String action; // "Encrypt" or "Decrypt"
  final String inputText;
  final String outputText;
  final int? shift; // For Caesar only
  final String? key; // For Playfair only
  final List<String> steps; // Step-by-step transformations
  final Timestamp? createdAt; // Firestore server timestamp

  FirestoreHistoryItem({
    this.id,
    required this.cipherType,
    required this.action,
    required this.inputText,
    required this.outputText,
    this.shift,
    this.key,
    required this.steps,
    this.createdAt,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'cipherType': cipherType,
      'action': action,
      'inputText': inputText,
      'outputText': outputText,
      'shift': shift,
      'key': key,
      'steps': steps,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document
  factory FirestoreHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirestoreHistoryItem(
      id: doc.id,
      cipherType: data['cipherType'] ?? '',
      action: data['action'] ?? '',
      inputText: data['inputText'] ?? '',
      outputText: data['outputText'] ?? '',
      shift: data['shift'],
      key: data['key'],
      steps: List<String>.from(data['steps'] ?? []),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Create from Map
  factory FirestoreHistoryItem.fromMap(Map<String, dynamic> map) {
    return FirestoreHistoryItem(
      id: map['id'],
      cipherType: map['cipherType'] ?? '',
      action: map['action'] ?? '',
      inputText: map['inputText'] ?? '',
      outputText: map['outputText'] ?? '',
      shift: map['shift'],
      key: map['key'],
      steps: List<String>.from(map['steps'] ?? []),
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  /// Get formatted date
  String getFormattedDate() {
    if (createdAt == null) return 'Just now';
    final date = createdAt!.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
