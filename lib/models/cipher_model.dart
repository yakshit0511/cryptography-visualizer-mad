import 'package:cloud_firestore/cloud_firestore.dart';

class CipherModel {
  String id;
  String inputText;
  String cipherType;
  String key;
  String resultText;
  Timestamp createdAt;

  CipherModel({
    required this.id,
    required this.inputText,
    required this.cipherType,
    required this.key,
    required this.resultText,
    required this.createdAt,
  });

  // Convert Firestore document → Dart object
  factory CipherModel.fromMap(Map<String, dynamic> map, String docId) {
    return CipherModel(
      id: docId,
      inputText: map['inputText'],
      cipherType: map['cipherType'],
      key: map['key'],
      resultText: map['resultText'],
      createdAt: map['createdAt'],
    );
  }

  // Convert Dart object → Firestore document
  Map<String, dynamic> toMap() {
    return {
      'inputText': inputText,
      'cipherType': cipherType,
      'key': key,
      'resultText': resultText,
      'createdAt': createdAt,
    };
  }
}
