import 'package:cloud_firestore/cloud_firestore.dart';

class BookPage {
  String pageNumber;
  String originalImagePath;
  String? annotatedImagePath;
  String? detectedText;
  String? explanation;
  double? confidence;
  List<String>? detectedRows;
  DateTime processedAt;

  BookPage({
    required this.pageNumber,
    required this.originalImagePath,
    this.annotatedImagePath,
    this.detectedText,
    this.explanation,
    this.confidence,
    this.detectedRows,
    required this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'pageNumber': pageNumber,
      'originalImagePath': originalImagePath,
      'annotatedImagePath': annotatedImagePath,
      'detectedText': detectedText,
      'explanation': explanation,
      'confidence': confidence,
      'detectedRows': detectedRows,
      'processedAt': Timestamp.fromDate(processedAt),
    };
  }

  factory BookPage.fromMap(Map<String, dynamic> map) {
    return BookPage(
      pageNumber: map['pageNumber'] ?? '',
      originalImagePath: map['originalImagePath'] ?? '',
      annotatedImagePath: map['annotatedImagePath'],
      detectedText: map['detectedText'],
      explanation: map['explanation'],
      confidence: map['confidence']?.toDouble(),
      detectedRows: map['detectedRows'] != null ? List<String>.from(map['detectedRows']) : null,
      processedAt: (map['processedAt'] as Timestamp).toDate(),
    );
  }
}

class Book {
  String name;
  DateTime createdAt;
  DateTime modifiedAt;
  List<BookPage>? pages;
  int totalPages;

  Book({
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    this.pages,
    this.totalPages = 0,
  });

  // Convert Book object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
      'totalPages': totalPages,
    };
  }

  // Create Book object from Firestore document data
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      modifiedAt: (map['modifiedAt'] as Timestamp).toDate(),
      totalPages: map['totalPages'] ?? 0,
    );
  }

  // Optional: Add a copyWith method for easy updates
  Book copyWith({
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<BookPage>? pages,
    int? totalPages,
  }) {
    return Book(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      pages: pages ?? this.pages,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  // Optional: Override toString for debugging
  @override
  String toString() {
    return 'Book(name: $name, createdAt: $createdAt, modifiedAt: $modifiedAt, totalPages: $totalPages)';
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