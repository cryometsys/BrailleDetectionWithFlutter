import 'package:cloud_firestore/cloud_firestore.dart';

// First, define the Message class
class Message {
  String id;
  String content;
  String senderId;
  String receiverId;
  Timestamp timestamp;
  bool isRead;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    this.isRead = false,
  });

  Message.fromJson(Map<String, Object?> json)
      : this(
          id: json['id']! as String,
          content: json['content']! as String,
          senderId: json['senderId']! as String,
          receiverId: json['receiverId']! as String,
          timestamp: json['timestamp']! as Timestamp,
          isRead: json['isRead'] as bool? ?? false,
        );

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}

class Users {
  String firstName;
  String lastName;
  String mail;
  String? gender;
  Timestamp createdOn;
  Timestamp updatedOn;
  Timestamp? birthDate;
  List<String> books;
  List<Message> messages; // Fixed the syntax error

  Users({
    required this.firstName,
    required this.lastName,
    required this.mail,
    required this.createdOn,
    required this.updatedOn,
    this.gender,
    this.birthDate,
    required this.books,
    required this.messages,
  });

  Users.fromJson(Map<String, Object?> json)
      : this(
          firstName: json['firstName']! as String,
          lastName: json['lastName']! as String,
          mail: json['mail']! as String,
          gender: json['gender'] as String?,
          createdOn: json['createdOn']! as Timestamp,
          updatedOn: json['updatedOn']! as Timestamp,
          birthDate: json['birthDate'] as Timestamp?,
          books: (json['books'] as List<dynamic>?)?.cast<String>() ?? [],
          messages: (json['messages'] as List<dynamic>?)
                  ?.map((messageJson) => Message.fromJson(messageJson as Map<String, Object?>))
                  .toList() ??
              [],
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
    List<Message>? messages,
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
      messages: messages ?? this.messages,
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
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }
}