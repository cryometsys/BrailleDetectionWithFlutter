import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/braille_detection_result.dart';

class BrailleApiClient {
  static const String baseUrl = 'https://meheru-braille-assistant.hf.space';

  static Future<BrailleDetectionResult> detectBraille(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('Sending request to: $baseUrl/api/predict');
      final response = await http.post(
        Uri.parse('$baseUrl/api/predict'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'task': 'detect_braille',
          'image_base64': base64Image,
          'min_confidence': 0.4,
        }),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return BrailleDetectionResult.fromJson(responseData);
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in detectBraille: $e');
      throw Exception('Connection failed: $e');
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Accept': 'application/json'},
      );

      print('Health check status: ${response.statusCode}');
      print('Health check response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  static Future<BrailleDetectionResult> mockDetection() async {
    await Future.delayed(const Duration(seconds: 2));
    return BrailleDetectionResult(
      processedText: 'hello world',
      explanation: 'Sample braille detection result showing text that reads "hello world". This demonstrates the basic braille to text conversion functionality.',
      confidence: 0.85,
      detectedRows: ['hello', 'world'],
      totalCharacters: 11,
      annotatedImageBase64: null, // No annotated image in mock
    );
  }
}