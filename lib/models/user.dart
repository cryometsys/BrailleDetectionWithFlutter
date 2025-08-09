import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  String firstName;
  String lastName;
  String mail;
  String? gender;
  Timestamp createdOn;
  Timestamp updatedOn;
  Timestamp? birthDate;

  Users({
    required this.firstName,
    required this.lastName,
    required this.mail,
    required this.createdOn,
    required this.updatedOn,
    required this.gender,
    required this.birthDate
  });

  Users.fromJson(Map<String, Object?> json)
      : firstName = json['firstName'] as String? ?? '',
        lastName = json['lastName'] as String? ?? '',
        mail = json['mail'] as String? ?? '',
        gender = json['gender'] as String?,
        createdOn = json['createdOn'] as Timestamp? ?? Timestamp.now(),
        updatedOn = json['updatedOn'] as Timestamp? ?? Timestamp.now(),
        birthDate = json['birthDate'] as Timestamp?;


  Users copyWith({
    String? firstName,
    String? lastName,
    String? mail,
    String? gender,
    Timestamp? createdOn,
    Timestamp? updatedOn,
    Timestamp? birthDate,
  }) {
    return Users(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mail: mail ?? this.mail,
      createdOn: createdOn ?? this.createdOn,
      updatedOn: updatedOn ?? this.updatedOn,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
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
    };
  }
}
