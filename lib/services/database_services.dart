import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:new_flutter_demo/models/user.dart';
// Import your new models here

class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Python API endpoint - change this to your actual server URL
  static const String _pythonApiUrl = 'http://localhost:5000/api';
  // For production: static const String _pythonApiUrl = 'https://your-api-domain.com/api';

  // ==================== AUTH METHODS ====================
  
  Future<UserCredential?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      return null;
    }
  }

  Future<void> storeUserCredentials(String email, String password) async {
    await _secureStorage.write(key: 'email', value: email);
    await _secureStorage.write(key: 'password', value: password);
  }

  Future<void> clearUserCredentials() async {
    await _secureStorage.delete(key: 'email');
    await _secureStorage.delete(key: 'password');
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
    await _secureStorage.delete(key: 'email');
    await _secureStorage.delete(key: 'password');
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
      birthDate: null,
      books: [],
      messages: [],
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

  // ==================== BRAILLE PROCESSING METHODS ====================

  Future<String?> uploadImageToStorage(File imageFile) async {
    try {
      String fileName = 'braille_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      
      TaskSnapshot snapshot = await _storage.ref().child(fileName).putFile(imageFile);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String> _imageToBase64(File imageFile) async {
    Uint8List imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<BrailleApiResponse> detectBraille(File imageFile) async {
    try {
      // Convert image to base64
      String base64Image = await _imageToBase64(imageFile);
      
      // Call Python API
      final response = await http.post(
        Uri.parse('$_pythonApiUrl/detect-braille'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return BrailleApiResponse.fromJson(responseData);
      } else {
        return BrailleApiResponse(
          success: false,
          error: 'API call failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BrailleApiResponse(
        success: false,
        error: 'Error calling braille API: $e',
      );
    }
  }

  Future<ChatApiResponse> chatWithAssistant(String message, {String? threadId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_pythonApiUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'thread_id': threadId,
        }),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return ChatApiResponse.fromJson(responseData);
      } else {
        return ChatApiResponse(
          success: false,
          error: 'Chat API call failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ChatApiResponse(
        success: false,
        error: 'Error calling chat API: $e',
      );
    }
  }

  Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(Uri.parse('$_pythonApiUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== BRAILLE RESULT STORAGE ====================

  Future<String?> saveBrailleDetectionResult(BrailleDetectionResult result) async {
    try {
      DocumentReference docRef = _firestore.collection('braille_detections').doc();
      
      BrailleDetectionResult resultWithId = BrailleDetectionResult(
        id: docRef.id,
        userId: result.userId,
        originalImageUrl: result.originalImageUrl,
        annotatedImageBase64: result.annotatedImageBase64,
        detectedRows: result.detectedRows,
        processedText: result.processedText,
        explanation: result.explanation,
        confidence: result.confidence,
        characterCount: result.characterCount,
        createdAt: result.createdAt,
        updatedAt: Timestamp.now(),
      );

      await docRef.set(resultWithId.toJson());
      return docRef.id;
    } catch (e) {
      print('Error saving braille result: $e');
      return null;
    }
  }

  Future<List<BrailleDetectionResult>> getUserBrailleResults(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('braille_detections')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BrailleDetectionResult.fromJson(doc.data() as Map<String, Object?>))
          .toList();
    } catch (e) {
      print('Error getting braille results: $e');
      return [];
    }
  }

  Future<BrailleDetectionResult?> getBrailleResult(String resultId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('braille_detections').doc(resultId).get();
      if (doc.exists) {
        return BrailleDetectionResult.fromJson(doc.data() as Map<String, Object?>);
      }
      return null;
    } catch (e) {
      print('Error getting braille result: $e');
      return null;
    }
  }

  // ==================== CHAT METHODS ====================

  Future<String?> createChatThread(List<String> participantIds, String threadType) async {
    try {
      DocumentReference docRef = _firestore.collection('chat_threads').doc();
      
      ChatThread thread = ChatThread(
        id: docRef.id,
        participantIds: participantIds,
        threadType: threadType,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      await docRef.set(thread.toJson());
      return docRef.id;
    } catch (e) {
      print('Error creating chat thread: $e');
      return null;
    }
  }

  Future<void> sendChatMessage(ChatMessage message) async {
    try {
      // Save message
      await _firestore.collection('chat_messages').doc(message.id).set(message.toJson());

      // Update thread's last message info if receiverId exists (not AI chat)
      if (message.receiverId != null) {
        String threadId = _generateThreadId([message.senderId, message.receiverId!]);
        await _firestore.collection('chat_threads').doc(threadId).update({
          'lastMessageContent': message.content,
          'lastMessageTime': message.timestamp,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  String _generateThreadId(List<String> participantIds) {
    List<String> sortedIds = List.from(participantIds)..sort();
    return sortedIds.join('_');
  }

  Future<List<ChatMessage>> getChatMessages(String threadId, {int limit = 50}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chat_messages')
          .where('threadId', isEqualTo: threadId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      List<ChatMessage> messages = snapshot.docs
          .map((doc) => ChatMessage.fromJson(doc.data() as Map<String, Object?>))
          .toList();

      return messages.reversed.toList(); // Return in chronological order
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  Future<List<ChatThread>> getUserChatThreads(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chat_threads')
          .where('participantIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ChatThread.fromJson(doc.data() as Map<String, Object?>))
          .toList();
    } catch (e) {
      print('Error getting chat threads: $e');
      return [];
    }
  }

  // ==================== INTEGRATED WORKFLOW ====================

  Future<BrailleDetectionResult?> processAndSaveBrailleImage(File imageFile) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      // Step 1: Upload original image to Firebase Storage
      String? imageUrl = await uploadImageToStorage(imageFile);
      if (imageUrl == null) return null;

      // Step 2: Process with Python API
      BrailleApiResponse apiResponse = await detectBraille(imageFile);
      if (!apiResponse.success) return null;

      // Step 3: Create result object
      BrailleDetectionResult result = BrailleDetectionResult(
        id: '', // Will be set when saving
        userId: userId,
        originalImageUrl: imageUrl,
        annotatedImageBase64: apiResponse.annotatedImageBase64,
        detectedRows: apiResponse.detectedRows ?? [],
        processedText: apiResponse.processedText ?? '',
        explanation: apiResponse.explanation ?? '',
        confidence: apiResponse.confidence ?? 0.0,
        characterCount: apiResponse.characterCount ?? 0,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // Step 4: Save to Firestore
      String? savedId = await saveBrailleDetectionResult(result);
      if (savedId == null) return null;

      // Return result with ID
      return BrailleDetectionResult(
        id: savedId,
        userId: result.userId,
        originalImageUrl: result.originalImageUrl,
        annotatedImageBase64: result.annotatedImageBase64,
        detectedRows: result.detectedRows,
        processedText: result.processedText,
        explanation: result.explanation,
        confidence: result.confidence,
        characterCount: result.characterCount,
        createdAt: result.createdAt,
        updatedAt: result.updatedAt,
      );

    } catch (e) {
      print('Error in integrated braille processing: $e');
      return null;
    }
  }
}