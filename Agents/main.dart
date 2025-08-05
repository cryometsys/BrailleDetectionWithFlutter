// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

void main() {
  runApp(BrailleDetectorApp());
}

class BrailleDetectorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braille Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BrailleDetectorScreen(),
    );
  }
}

class BrailleDetectorScreen extends StatefulWidget {
  @override
  _BrailleDetectorScreenState createState() => _BrailleDetectorScreenState();
}

class _BrailleDetectorScreenState extends State<BrailleDetectorScreen> {
  final ImagePicker _picker = ImagePicker();
  final String apiUrl = 'http://localhost:5000/api'; // Change to your server URL
  
  String? sessionId;
  List<DetectionResult> detectionResults = [];
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    createSession();
  }
  
  Future<void> createSession() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/create-session'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          sessionId = data['session_id'];
        });
      }
    } catch (e) {
      print('Error creating session: $e');
      // Fallback to local session ID
      setState(() {
        sessionId = Uuid().v4();
      });
    }
  }
  
  Future<void> pickAndProcessImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          isLoading = true;
        });
        
        await processImage(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> takePhotoAndProcess() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          isLoading = true;
        });
        
        await processImage(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> processImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/process-braille'),
      );
      
      request.fields['session_id'] = sessionId ?? '';
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          final result = DetectionResult.fromJson(data['result']);
          setState(() {
            detectionResults.insert(0, result);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Braille detected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data['error'] ?? 'Processing failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Braille Detector'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Action buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : takePhotoAndProcess,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : pickAndProcessImage,
                    icon: Icon(Icons.photo_library),
                    label: Text('Pick Image'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading indicator
          if (isLoading)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Processing braille image...'),
                ],
              ),
            ),
          
          // Session info
          if (sessionId != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Session: ${sessionId!.substring(0, 8)}...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          
          SizedBox(height: 8),
          
          // Results list
          Expanded(
            child: detectionResults.isEmpty && !isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No braille detections yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Take a photo or pick an image to start',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: detectionResults.length,
                    itemBuilder: (context, index) {
                      return DetectionResultCard(
                        result: detectionResults[index],
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DetectionResultCard extends StatelessWidget {
  final DetectionResult result;
  final int index;
  
  const DetectionResultCard({
    Key? key,
    required this.result,
    required this.index,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Detection #${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(result.confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(result.confidence * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Images row
            if (result.annotatedImage != null)
              Container(
                height: 200,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    result.annotatedImage!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(Icons.error, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
            
            SizedBox(height: 16),
            
            // Detected text rows
            if (result.detectedRows.isNotEmpty) ...[
              Text(
                'Detected Characters:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.detectedRows.map((row) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      row,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  )).toList(),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Processed text
            if (result.processedText.isNotEmpty) ...[
              Text(
                'Processed Text:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  result.processedText,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Explanation
            if (result.explanation.isNotEmpty) ...[
              Text(
                'Explanation:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                result.explanation,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            
            // Character count
            if (result.characterCount > 0) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '${result.characterCount} characters detected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class DetectionResult {
  final String? originalImage;
  final String? annotatedImage;
  final List<String> detectedRows;
  final String processedText;
  final String explanation;
  final double confidence;
  final int characterCount;
  
  DetectionResult({
    this.originalImage,
    this.annotatedImage,
    required this.detectedRows,
    required this.processedText,
    required this.explanation,
    required this.confidence,
    required this.characterCount,
  });
  
  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      originalImage: json['original_image'],
      annotatedImage: json['annotated_image'],
      detectedRows: List<String>.from(json['detected_rows'] ?? []),
      processedText: json['processed_text'] ?? '',
      explanation: json['explanation'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      characterCount: json['character_count'] ?? 0,
    );
  }
}