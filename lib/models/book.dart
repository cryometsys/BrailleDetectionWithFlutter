import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  String name;
  DateTime createdAt;
  DateTime modifiedAt;

  Book({required this.name, required this.createdAt, required this.modifiedAt});

  // Convert Book object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
    };
  }

  // Create Book object from Firestore document data
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      modifiedAt: (map['modifiedAt'] as Timestamp).toDate(),
    );
  }

  // Optional: Add a copyWith method for easy updates
  Book copyWith({
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Book(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  // Optional: Override toString for debugging
  @override
  String toString() {
    return 'Book(name: $name, createdAt: $createdAt, modifiedAt: $modifiedAt)';
  }

  // Optional: Override equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt;
  }

  @override
  int get hashCode {
    return name.hashCode ^ createdAt.hashCode ^ modifiedAt.hashCode;
  }
}
