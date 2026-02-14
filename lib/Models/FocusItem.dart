import 'package:cloud_firestore/cloud_firestore.dart';

class FocusItem {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;

  FocusItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    this.isDone = false,
    required this.createdAt,
    this.completedAt,
  });

  // Convert FocusItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Create FocusItem from Firestore document
  factory FocusItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FocusItem(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      category: data['category'] ?? 'Personal',
      isDone: data['isDone'] ?? false,
      createdAt: DateTime.parse(data['createdAt']),
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'])
          : null,
    );
  }

  // Create a copy with updated properties
  FocusItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? category,
    bool? isDone,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return FocusItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}