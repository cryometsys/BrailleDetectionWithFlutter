import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:new_flutter_demo/models/user.dart';

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<UserCredential?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle errors
      return null;
    }
  }

  Future<void> storeUserCredentials(String email, String password) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
  }

  Future<void> clearUserCredentials() async {
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
  }

  Future<UserCredential?> signupUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      return null;
    }
  }

  Future<void> saveUserData(UserCredential userCredential, String userFirstName, String userLastName) async {
    Users newUser = Users(
      firstName: userFirstName,
      lastName: userLastName,
      mail: userCredential.user!.email!,
      gender: null,
      createdOn: Timestamp.now(),
      updatedOn: Timestamp.now(),
      birthDate: null
    );

    await _firestore.collection('users').doc(userCredential.user?.uid).set(newUser.toJson());
  }

  Future<Users?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return Users.fromJson(doc.data() as Map<String, Object?>);
    }
    return null;
  }

  Future<void> updateUserData(String uid, Users updatedUser) async {
    await _firestore.collection('users').doc(uid).update(updatedUser.toJson());
  }

}