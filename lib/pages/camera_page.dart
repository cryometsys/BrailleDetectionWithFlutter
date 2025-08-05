// Updated Camera Page with corrected imports
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Your app-specific imports
import 'package:new_flutter_demo/models/book.dart';
import 'package:new_flutter_demo/models/user.dart';
import 'package:new_flutter_demo/models/braille_models.dart';
import 'package:new_flutter_demo/styles/app_colors.dart';
import '../services/database_services.dart';

// Updated Book model to handle braille processing
class Book {
  String name;
  DateTime createdAt;
  DateTime modifiedAt;

  // New fields for braille processing
  List<String> imageUrls;
  List<BraillePageResult> braillePages;
  String bookType; // 'regular', 'braille_detected', 'braille_processed'

  Book({
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    this.imageUrls = const [],
    this.braillePages = const [],
    this.bookType = 'regular',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
      'imageUrls': imageUrls,
      'braillePages': braillePages.map((page) => page.toMap()).toList(),
      'bookType': bookType,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      modifiedAt: (map['modifiedAt'] as Timestamp).toDate(),
      imageUrls: (map['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      braillePages: (map['braillePages'] as List<dynamic>?)
              ?.map((pageMap) =>
                  BraillePageResult.fromMap(pageMap as Map<String, dynamic>))
              .toList() ??
          [],
      bookType: map['bookType'] ?? 'regular',
    );
  }
}

// Model for individual braille page results within a book
class BraillePageResult {
  final int pageNumber;
  final String originalImageUrl;
  final String? annotatedImageBase64;
  final List<String> detectedRows;
  final String processedText;
  final String explanation;
  final double confidence;
  final int characterCount;
  final DateTime processedAt;

  BraillePageResult({
    required this.pageNumber,
    required this.originalImageUrl,
    this.annotatedImageBase64,
    required this.detectedRows,
    required this.processedText,
    required this.explanation,
    required this.confidence,
    required this.characterCount,
    required this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'pageNumber': pageNumber,
      'originalImageUrl': originalImageUrl,
      'annotatedImageBase64': annotatedImageBase64,
      'detectedRows': detectedRows,
      'processedText': processedText,
      'explanation': explanation,
      'confidence': confidence,
      'characterCount': characterCount,
      'processedAt': Timestamp.fromDate(processedAt),
    };
  }

  factory BraillePageResult.fromMap(Map<String, dynamic> map) {
    return BraillePageResult(
      pageNumber: map['pageNumber'] ?? 0,
      originalImageUrl: map['originalImageUrl'] ?? '',
      annotatedImageBase64: map['annotatedImageBase64'],
      detectedRows:
          (map['detectedRows'] as List<dynamic>?)?.cast<String>() ?? [],
      processedText: map['processedText'] ?? '',
      explanation: map['explanation'] ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      characterCount: (map['characterCount'] as num?)?.toInt() ?? 0,
      processedAt: (map['processedAt'] as Timestamp).toDate(),
    );
  }
}

enum ProcessingMode { detectionOnly, fullProcessing, none }

class CameraPage extends StatefulWidget {
  final List<String> pathImage;

  const CameraPage({
    super.key,
    required this.pathImage,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  TextEditingController? nameController;
  final DatabaseService _databaseService = DatabaseService();

  // Processing state
  bool _isProcessing = false;
  bool _showBrailleResults = false;
  List<BraillePageResult> _brailleResults = [];

  // Processing mode selection
  ProcessingMode _selectedMode = ProcessingMode.none;

  @override
  void initState() {
    nameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    nameController?.dispose();
    super.dispose();
  }

  Future<void> saveImages(String bookName) async {
    final Directory? rootDir = await getExternalStorageDirectory();
    final String imgPath = '${rootDir!.path}/braillify/$bookName/img';
    final String pagePath = '${rootDir.path}/braillify/$bookName/pages';
    final Directory directory = Directory(imgPath);
    if (!await directory.exists()) await directory.create(recursive: true);
    final Directory pgDirectory = Directory(pagePath);
    if (!await pgDirectory.exists()) await pgDirectory.create(recursive: true);

    for (int i = 0; i < widget.pathImage.length; i++) {
      String imagePath = widget.pathImage[i];
      File sourceFile = File(imagePath);
      String newFilePath = '$imgPath/image${i + 1}.jpeg';
      await sourceFile.copy(newFilePath);
    }
  }

  // Updated method to process braille and save as a book
  Future<void> _processBrailleDetectionOnly() async {
    setState(() {
      _isProcessing = true;
      _brailleResults.clear();
    });

    try {
      List<String> uploadedImageUrls = [];

      for (int i = 0; i < widget.pathImage.length; i++) {
        File imageFile = File(widget.pathImage[i]);

        // Upload image to Firebase Storage
        String? imageUrl =
            await _databaseService.uploadImageToStorage(imageFile);
        if (imageUrl != null) {
          uploadedImageUrls.add(imageUrl);
        }

        // Call detection-only API
        BrailleApiResponse response =
            await _databaseService.detectBrailleOnly(imageFile);

        if (response.success) {
          BraillePageResult pageResult = BraillePageResult(
            pageNumber: i + 1,
            originalImageUrl: imageUrl ?? '',
            annotatedImageBase64: response.annotatedImageBase64,
            detectedRows: response.detectedRows ?? [],
            processedText: '', // No processing in detection-only mode
            explanation: 'Detection only - no AI processing performed',
            confidence: response.confidence ?? 0.0,
            characterCount: response.characterCount ?? 0,
            processedAt: DateTime.now(),
          );

          _brailleResults.add(pageResult);
        } else {
          _showErrorSnackBar(
              'Detection failed for image ${i + 1}: ${response.error}');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error during detection: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _showBrailleResults = true;
      });
    }
  }

  Future<void> _processBrailleFull() async {
    setState(() {
      _isProcessing = true;
      _brailleResults.clear();
    });

    try {
      List<String> uploadedImageUrls = [];

      for (int i = 0; i < widget.pathImage.length; i++) {
        File imageFile = File(widget.pathImage[i]);

        // Upload image to Firebase Storage
        String? imageUrl =
            await _databaseService.uploadImageToStorage(imageFile);
        if (imageUrl != null) {
          uploadedImageUrls.add(imageUrl);
        }

        // Call full processing API
        BrailleApiResponse response =
            await _databaseService.processBrailleFull(imageFile);

        if (response.success) {
          BraillePageResult pageResult = BraillePageResult(
            pageNumber: i + 1,
            originalImageUrl: imageUrl ?? '',
            annotatedImageBase64: response.annotatedImageBase64,
            detectedRows: response.detectedRows ?? [],
            processedText: response.processedText ?? '',
            explanation: response.explanation ?? '',
            confidence: response.confidence ?? 0.0,
            characterCount: response.characterCount ?? 0,
            processedAt: DateTime.now(),
          );

          _brailleResults.add(pageResult);
        } else {
          _showErrorSnackBar(
              'Full processing failed for image ${i + 1}: ${response.error}');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error during full processing: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _showBrailleResults = true;
      });
    }
  }

  Future<void> checkAndSaveBook() async {
    String bookName = nameController!.text.trim();
    if (bookName.isEmpty) {
      _showErrorSnackBar('Name Field Is Empty');
      return;
    }

    final String userId = FirebaseAuth.instance.currentUser!.uid;

    // Check if book name already exists
    final QuerySnapshot existingBooks = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('books')
        .where('name', isEqualTo: bookName)
        .get();

    if (existingBooks.docs.isNotEmpty) {
      _showErrorSnackBar('Book Name Already Exists');
      return;
    }

    // Save images locally
    await saveImages(bookName);

    // Create book with braille processing results
    String bookType = 'regular';
    if (_selectedMode == ProcessingMode.detectionOnly) {
      bookType = 'braille_detected';
    } else if (_selectedMode == ProcessingMode.fullProcessing) {
      bookType = 'braille_processed';
    }

    Book newBook = Book(
      name: bookName,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
      imageUrls:
          _brailleResults.map((result) => result.originalImageUrl).toList(),
      braillePages: _brailleResults,
      bookType: bookType,
    );

    // Save book to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('books')
        .doc(bookName)
        .set(newBook.toMap());

    // Update user's books list
    await _updateUserBooksList(userId, bookName);

    _showSuccessSnackBar('Book Saved Successfully');
    Navigator.pop(context);
  }

  Future<void> _updateUserBooksList(String userId, String bookName) async {
    try {
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userDoc.update({
        'books': FieldValue.arrayUnion([bookName]),
        'updatedOn': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating user books list: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildProcessingModeSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Processing Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            RadioListTile<ProcessingMode>(
              title: const Text('Save as Regular Book'),
              subtitle: const Text('No braille processing'),
              value: ProcessingMode.none,
              groupValue: _selectedMode,
              onChanged: (ProcessingMode? value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
              activeColor: AppColors.primaryBlue,
            ),
            RadioListTile<ProcessingMode>(
              title: const Text('Detection Only'),
              subtitle: const Text('Quick braille character detection'),
              value: ProcessingMode.detectionOnly,
              groupValue: _selectedMode,
              onChanged: (ProcessingMode? value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
              activeColor: AppColors.primaryBlue,
            ),
            RadioListTile<ProcessingMode>(
              title: const Text('Full Processing'),
              subtitle: const Text('Detection + AI processing + explanation'),
              value: ProcessingMode.fullProcessing,
              groupValue: _selectedMode,
              onChanged: (ProcessingMode? value) {
                setState(() {
                  _selectedMode = value!;
                });
              },
              activeColor: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingButton() {
    if (_selectedMode == ProcessingMode.none) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: _isProcessing
            ? null
            : () async {
                if (_selectedMode == ProcessingMode.detectionOnly) {
                  await _processBrailleDetectionOnly();
                } else if (_selectedMode == ProcessingMode.fullProcessing) {
                  await _processBrailleFull();
                }
              },
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.visibility),
        label: Text(_isProcessing ? 'Processing...' : 'Process Braille Images'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildBrailleResults() {
    if (!_showBrailleResults || _brailleResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Braille Processing Results',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            ..._brailleResults.asMap().entries.map((entry) {
              int index = entry.key;
              BraillePageResult result = entry.value;

              return ExpansionTile(
                title: Text('Page ${index + 1}'),
                subtitle: Text(
                    'Characters: ${result.characterCount}, Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (result.detectedRows.isNotEmpty) ...[
                          const Text('Detected Text:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(result.detectedRows.join(' ')),
                          const SizedBox(height: 8),
                        ],
                        if (result.processedText.isNotEmpty) ...[
                          const Text('Processed Text:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(result.processedText),
                          const SizedBox(height: 8),
                        ],
                        if (result.explanation.isNotEmpty) ...[
                          const Text('Explanation:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(result.explanation),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Book'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Image preview
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.pathImage.map((path) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16.0),

          // Book name input
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Book Name',
              labelStyle: TextStyle(
                color: AppColors.primaryBlue,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            cursorColor: AppColors.primaryBlue,
          ),

          const SizedBox(height: 16.0),

          // Processing mode selector
          _buildProcessingModeSelector(),

          // Processing button
          _buildProcessingButton(),

          // Results display
          _buildBrailleResults(),
        ],
      ),
      bottomNavigationBar: InkWell(
        onTap: () async {
          await checkAndSaveBook();
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 52,
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              "Save Book",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
