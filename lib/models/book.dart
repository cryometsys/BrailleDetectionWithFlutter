import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  String name;
  DateTime createdAt;
  DateTime modifiedAt;

  Book({required this.name, required this.createdAt, required this.modifiedAt});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
    };
  }
}
