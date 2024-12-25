import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  String firstName;
  String lastName;
  String mail;
  String? gender;
  Timestamp createdOn;
  Timestamp updatedOn;
  Timestamp? birthDate;
  List<String> books;

  Users({
    required this.firstName,
    required this.lastName,
    required this.mail,
    required this.createdOn,
    required this.updatedOn,
    required this.gender,
    required this.birthDate,
    required this.books,
  });

  Users.fromJson(Map<String, Object?> json)
      : this(
          firstName: json['firstName']! as String,
          lastName: json['lastName']! as String,
          mail: json['mail']! as String,
          gender: json['gender']! as String,
          createdOn: json['createdOn']! as Timestamp,
          updatedOn: json['updatedOn']! as Timestamp,
          birthDate: json['birthDate']! as Timestamp,
          books: json['books']! as List<String>,
        );

  Users copyWith({
    String? firstName,
    String? lastName,
    String? mail,
    String? gender,
    Timestamp? createdOn,
    Timestamp? updatedOn,
    Timestamp? birthDate,
    List<String>? books,
  }) {
    return Users(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mail: mail ?? this.mail,
      createdOn: createdOn ?? this.createdOn,
      updatedOn: updatedOn ?? this.updatedOn,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      books: books ?? this.books,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'mail': mail,
      'gender': gender,
      'createdOn': createdOn,
      'updatedOn': updatedOn,
      'birthDate': birthDate,
      'books': books,
    };
  }
}
