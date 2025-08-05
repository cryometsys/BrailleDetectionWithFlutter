import 'package:cloud_firestore/cloud_firestore.dart';

// Braille Detection Result Model
class BrailleDetectionResult {
  final String id;
  final String userId;
  final String originalImageUrl;
  final String? annotatedImageBase64;
  final List<String> detectedRows;
  final String processedText;
  final String explanation;
  final double confidence;
  final int characterCount;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  BrailleDetectionResult({
    required this.id,
    required this.userId,
    required this.originalImageUrl,
    this.annotatedImageBase64,
    required this.detectedRows,
    required this.processedText,
    required this.explanation,
    required this.confidence,
    required this.characterCount,
    required this.createdAt,
    required this.updatedAt,
  });

  BrailleDetectionResult.fromJson(Map<String, Object?> json)
      : this(
          id: json['id']! as String,
          userId: json['userId']! as String,
          originalImageUrl: json['originalImageUrl']! as String,
          annotatedImageBase64: json['annotatedImageBase64'] as String?,
          detectedRows: (json['detectedRows'] as List<dynamic>?)?.cast<String>() ?? [],
          processedText: json['processedText']! as String,
          explanation: json['explanation']! as String,
          confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
          characterCount: (json['characterCount'] as num?)?.toInt() ?? 0,
          createdAt: json['createdAt']! as Timestamp,
          updatedAt: json['updatedAt']! as Timestamp,
        );

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'userId': userId,
      'originalImageUrl': originalImageUrl,
      'annotatedImageBase64': annotatedImageBase64,
      'detectedRows': detectedRows,
      'processedText': processedText,
      'explanation': explanation,
      'confidence': confidence,
      'characterCount': characterCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// Chat Message Model (enhanced)
class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String? receiverId;
  final String messageType; // 'text', 'braille_result', 'system'
  final String? brailleResultId; // Reference to braille detection if applicable
  final Timestamp timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    this.receiverId,
    required this.messageType,
    this.brailleResultId,
    required this.timestamp,
    this.isRead = false,
  });

  ChatMessage.fromJson(Map<String, Object?> json)
      : this(
          id: json['id']! as String,
          content: json['content']! as String,
          senderId: json['senderId']! as String,
          receiverId: json['receiverId'] as String?,
          messageType: json['messageType']! as String,
          brailleResultId: json['brailleResultId'] as String?,
          timestamp: json['timestamp']! as Timestamp,
          isRead: json['isRead'] as bool? ?? false,
        );

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'receiverId': receiverId,
      'messageType': messageType,
      'brailleResultId': brailleResultId,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}

// Chat Thread Model
class ChatThread {
  final String id;
  final List<String> participantIds;
  final String? lastMessageContent;
  final Timestamp? lastMessageTime;
  final String threadType; // 'user_chat', 'ai_assistant', 'group'
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ChatThread({
    required this.id,
    required this.participantIds,
    this.lastMessageContent,
    this.lastMessageTime,
    required this.threadType,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatThread.fromJson(Map<String, Object?> json)
      : this(
          id: json['id']! as String,
          participantIds: (json['participantIds'] as List<dynamic>?)?.cast<String>() ?? [],
          lastMessageContent: json['lastMessageContent'] as String?,
          lastMessageTime: json['lastMessageTime'] as Timestamp?,
          threadType: json['threadType']! as String,
          createdAt: json['createdAt']! as Timestamp,
          updatedAt: json['updatedAt']! as Timestamp,
        );

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': lastMessageTime,
      'threadType': threadType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// API Response Models
class BrailleApiResponse {
  final bool success;
  final String? error;
  final List<String>? detectedRows;
  final String? processedText;
  final String? explanation;
  final double? confidence;
  final int? characterCount;
  final String? annotatedImageBase64;

  BrailleApiResponse({
    required this.success,
    this.error,
    this.detectedRows,
    this.processedText,
    this.explanation,
    this.confidence,
    this.characterCount,
    this.annotatedImageBase64,
  });

  factory BrailleApiResponse.fromJson(Map<String, dynamic> json) {
    return BrailleApiResponse(
      success: json['success'] ?? false,
      error: json['error'],
      detectedRows: (json['detected_rows'] as List<dynamic>?)?.cast<String>(),
      processedText: json['processed_text'],
      explanation: json['explanation'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      characterCount: (json['character_count'] as num?)?.toInt(),
      annotatedImageBase64: json['annotated_image_base64'],
    );
  }
}

class ChatApiResponse {
  final bool success;
  final String? error;
  final String? response;
  final String? threadId;

  ChatApiResponse({
    required this.success,
    this.error,
    this.response,
    this.threadId,
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    return ChatApiResponse(
      success: json['success'] ?? false,
      error: json['error'],
      response: json['response'],
      threadId: json['thread_id'],
    );
  }
}