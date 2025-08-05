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
  
  // Updated Python API endpoint to match your connector
  static const String _pythonApiUrl = 'http://localhost:5000/api';
  // For production: static const String _pythonApiUrl = 'https://your-api-domain.com/api';

  // ==================== AUTH METHODS (unchanged) ====================
  
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

  // ==================== BRAILLE PROCESSING METHODS (Updated) ====================

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

  Future<BrailleApiResponse> detectBrailleOnly(File imageFile) async {
    try {
      // Convert image to base64
      String base64Image = await _imageToBase64(imageFile);
      
      // Call detection-only route
      final response = await http.post(
        Uri.parse('$_pythonApiUrl/detect-braille-only'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return BrailleApiResponse.fromJson(responseData);
      } else {
        return BrailleApiResponse(
          success: false,
          error: 'Detection API call failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BrailleApiResponse(
        success: false,
        error: 'Error calling detection API: $e',
      );
    }
  }

  Future<BrailleApiResponse> processBrailleFull(File imageFile) async {
    try {
      // Convert image to base64
      String base64Image = await _imageToBase64(imageFile);
      
      // Call full processing route
      final response = await http.post(
        Uri.parse('$_pythonApiUrl/process-braille'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return BrailleApiResponse.fromJson(responseData);
      } else {
        return BrailleApiResponse(
          success: false,
          error: 'Full processing API call failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BrailleApiResponse(
        success: false,
        error: 'Error calling full processing API: $e',
      );
    }
  }

  // New method: Process already detected braille text strings
  Future<BrailleApiResponse> processBrailleText(List<String> textStrings) async {
    try {
      final response = await http.post(
        Uri.parse('$_pythonApiUrl/process-braille-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text_strings': textStrings}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        return BrailleApiResponse.fromJson(responseData);
      } else {
        return BrailleApiResponse(
          success: false,
          error: 'Text processing API call failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BrailleApiResponse(
        success: false,
        error: 'Error calling text processing API: $e',
      );
    }
  }

  // ==================== CHAT METHODS (Updated) ====================

  Future<ChatApiResponse> chatWithAI(String message, {String? threadId}) async {
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

  Future<void> saveChatToUserMessages(String userId, String userMessage, String aiResponse) async {
    try {
      // Get current user data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        Users currentUser = Users.fromJson(userDoc.data() as Map<String, Object?>);
        
        // Create new messages
        Message userMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: userMessage,
          senderId: userId,
          receiverId: 'ai_assistant',
          timestamp: Timestamp.now(),
          isRead: true,
        );
        
        Message aiMsg = Message(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          content: aiResponse,
          senderId: 'ai_assistant',
          receiverId: userId,
          timestamp: Timestamp.now(),
          isRead: false,
        );
        
        // Add messages to user's message list
        List<Message> updatedMessages = [...currentUser.messages, userMsg, aiMsg];
        
        // Update user document
        await _firestore.collection('users').doc(userId).update({
          'messages': updatedMessages.map((msg) => msg.toJson()).toList(),
          'updatedOn': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error saving chat to user messages: $e');
    }
  }

  // ==================== BOOK MANAGEMENT METHODS (unchanged) ====================

  Future<List<Book>> getUserBooks(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .orderBy('modifiedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user books: $e');
      return [];
    }
  }

  Future<Book?> getBook(String userId, String bookName) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .doc(bookName)
          .get();
          
      if (doc.exists) {
        return Book.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting book: $e');
      return null;
    }
  }

  Future<bool> updateBook(String userId, String bookName, Book updatedBook) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .doc(bookName)
          .update(updatedBook.toMap());
      return true;
    } catch (e) {
      print('Error updating book: $e');
      return false;
    }
  }

  Future<bool> deleteBook(String userId, String bookName) async {
    try {
      // Delete book document
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('books')
          .doc(bookName)
          .delete();
      
      // Remove from user's books list
      await _firestore.collection('users').doc(userId).update({
        'books': FieldValue.arrayRemove([bookName]),
        'updatedOn': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      print('Error deleting book: $e');
      return false;
    }
  }

  // ==================== MESSAGE MANAGEMENT METHODS (unchanged) ====================

  Future<List<Message>> getUserMessages(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        Users user = Users.fromJson(userDoc.data() as Map<String, Object?>);
        return user.messages;
      }
      return [];
    } catch (e) {
      print('Error getting user messages: $e');
      return [];
    }
  }

  Future<List<Message>> getUserChatWithAI(String userId) async {
    try {
      List<Message> allMessages = await getUserMessages(userId);
      
      // Filter messages where senderId is AI or receiverId is AI
      return allMessages.where((message) => 
        message.senderId == 'ai_assistant' || message.receiverId == 'ai_assistant'
      ).toList();
    } catch (e) {
      print('Error getting AI chat messages: $e');
      return [];
    }
  }

  // ==================== UTILITY METHODS ====================

  Future<String> _imageToBase64(File imageFile) async {
    Uint8List imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(Uri.parse('$_pythonApiUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== BRAILLE RESULT STORAGE (unchanged) ====================

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

  // ==================== INTEGRATED WORKFLOW (Updated) ====================

  Future<BrailleDetectionResult?> processAndSaveBrailleImage(File imageFile, {bool fullProcessing = true}) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      // Step 1: Upload original image to Firebase Storage
      String? imageUrl = await uploadImageToStorage(imageFile);
      if (imageUrl == null) return null;

      // Step 2: Process with Python API
      BrailleApiResponse apiResponse;
      if (fullProcessing) {
        apiResponse = await processBrailleFull(imageFile);
      } else {
        apiResponse = await detectBrailleOnly(imageFile);
      }
      
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

  // ==================== LEGACY METHODS (for backward compatibility) ====================

  Future<BrailleApiResponse> detectBraille(File imageFile) async {
    // Legacy method - defaults to full processing
    return processBrailleFull(imageFile);
  }

  Future<ChatApiResponse> chatWithAssistant(String message, {String? threadId}) async {
    // Legacy method - same as chatWithAI
    return chatWithAI(message, threadId: threadId);
  }
}