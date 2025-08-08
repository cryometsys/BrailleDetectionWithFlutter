//dart
import 'dart:convert';
import 'dart:io';
//packages
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
//firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_flutter_demo/models/book.dart';
//models
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/braille_detection_result.dart';
//api service
import 'package:new_flutter_demo/services/api_services.dart';
//styles
import '../styles/app_colors.dart';

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
  bool isProcessing = false;
  List<BrailleDetectionResult?> detectionResults = [];
  bool _abortRequested = false;
  bool _abortOpen = false;

  @override
  void initState() {
    nameController = TextEditingController();
    detectionResults =
        List.filled(widget.pathImage.length, null, growable: true);
    _abortRequested = false;
    _abortOpen = false;
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
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      print('Directory creation error: $e');
    }

    final Directory pgDirectory = Directory(pagePath);
    if (!await pgDirectory.exists()) await pgDirectory.create(recursive: true);

    for (int i = 0; i < widget.pathImage.length; i++) {
      String imagePath = widget.pathImage[i];
      File sourceFile = File(imagePath);
      String newFilePath = '$imgPath/image${i + 1}.jpeg';
      await sourceFile.copy(newFilePath);
    }
  }

  Future<void> saveBookPages(String bookName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bookRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .doc(bookName);

    final Directory? rootDir = await getExternalStorageDirectory();
    if (rootDir == null) {
      throw Exception("Unable to get external storage directory");
    }

    // Define folder paths for pages, explanations, and maps
    final String pageFolderPath = '${rootDir.path}/braillify/$bookName/pages';
    final String explFolderPath = '${rootDir.path}/braillify/$bookName/expl';
    final String mapFolderPath = '${rootDir.path}/braillify/$bookName/map';
    print('-->pageFolderPath: $pageFolderPath\n-->explFolder: $explFolderPath');
    final Directory pageFolder = Directory(pageFolderPath);
    if (!(await pageFolder.exists())) {
      await pageFolder.create(recursive: true);
    }
    final Directory explFolder = Directory(explFolderPath);
    if (!(await explFolder.exists())) {
      await explFolder.create(recursive: true);
    }
    final Directory mapFolder = Directory(mapFolderPath);
    if (!(await mapFolder.exists())) {
      await mapFolder.create(recursive: true);
    }

    // Loop through each image and save corresponding info
    for (int i = 0; i < widget.pathImage.length; i++) {
      final result = detectionResults[i];
      final pageNumber = 'page${i + 1}';

      // Save processed text to pages/pageX.txt
      if (result?.processedText != null) {
        final File pageFile = File('$pageFolderPath/page${i + 1}.txt');
        await pageFile.writeAsString(result!.processedText);
      }

      // Save explanation to expl/explX.txt
      if (result?.explanation != null) {
        final File explFile = File('$explFolderPath/expl${i + 1}.txt');
        await explFile.writeAsString(result!.explanation);
      }

      // Save annotated image as JPEG to map/mapX.jpeg
      if (result?.annotatedImageBase64 != null) {
        final File mapFile = File('$mapFolderPath/map${i + 1}.jpeg');
        final bytes = base64Decode(result!.annotatedImageBase64!);
        await mapFile.writeAsBytes(bytes);
      }

      // The original image path on device storage
      final String originalImagePath = '${rootDir.path}/braillify/$bookName/img/image${i + 1}.jpeg';

      // Create BookPage object and save to Firestore
      BookPage page = BookPage(
        pageNumber: pageNumber,
        originalImagePath: originalImagePath,
        detectedText: result?.processedText,
        explanation: result?.explanation,
        confidence: result?.confidence,
        detectedRows: result?.detectedRows,
        processedAt: DateTime.now(),
      );

      await bookRef.collection('pages').doc(pageNumber).set(page.toMap());
    }
  }
  Future<void> checkAndSaveBook() async {
    String bookName = nameController!.text.trim();
    if (bookName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name Field Is Empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final QuerySnapshot existingBooks = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('books')
        .where('name', isEqualTo: bookName)
        .get();
    if (existingBooks.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book Name Already Exists'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await saveImages(bookName);
      Book newBook = Book(
        name: bookName,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        totalPages: widget.pathImage.length,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('books')
          .doc(bookName)
          .set(newBook.toMap());
      await saveBookPages(bookName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document Saved'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving book: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSaveBookDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        TextEditingController dialogController = TextEditingController();
        return AlertDialog(
          title: const Text('Save Book'),
          content: TextField(
            controller: dialogController,
            decoration: const InputDecoration(
              labelText: 'Book Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String inputName = dialogController.text.trim();
                if (inputName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name Field Is Empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                nameController!.text = inputName;
                Navigator.of(ctx).pop();
                checkAndSaveBook();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showImageMenu(int index) async {
    String? selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 100, 0, 0),
      // adjust positioning as needed
      items: const [
        PopupMenuItem(value: 'showImage', child: Text('Show Image')),
        PopupMenuItem(
            value: 'showCharMapping', child: Text('Show character mapping')),
        PopupMenuItem(
            value: 'showCorrection', child: Text('Show AI powered text')),
        PopupMenuItem(
            value: 'showExplanation', child: Text('Show AI explanation')),
        PopupMenuItem(value: 'retake', child: Text('Retake image')),
        PopupMenuItem(value: 'delete', child: Text('Delete image')),
      ],
    );
    if (selected == null) return;
    final BrailleDetectionResult? result =
        detectionResults.length > index ? detectionResults[index] : null;
    switch (selected) {
      case 'showImage':
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (ctx) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              backgroundColor: Colors.black,
              body: Center(
                child: InteractiveViewer(
                  child: Image.file(
                    File(widget.pathImage[index]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
        break;

      case 'showCharMapping':
        if (result?.annotatedImageBase64 != null &&
            result!.annotatedImageBase64!.isNotEmpty) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Character Mapping'),
              content: SizedBox(
                width: double.maxFinite,
                child: InteractiveViewer(
                  // To allow zoom/pan on image
                  child:
                      Image.memory(base64Decode(result.annotatedImageBase64!)),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close')),
              ],
            ),
          );
        } else {
          _showPlaceholderDialog('No character mapping image available.');
        }
        break;

      case 'showExplanation':
        if (result?.explanation != null && result!.explanation.isNotEmpty) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('AI Explanation'),
              content: SingleChildScrollView(child: Text(result.explanation)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close')),
              ],
            ),
          );
        } else {
          _showPlaceholderDialog('No AI explanation available.');
        }
        break;

      case 'showCorrection':
        if (result?.processedText != null && result!.processedText.isNotEmpty) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Processed Text'),
              content: SingleChildScrollView(child: Text(result.processedText)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close')),
              ],
            ),
          );
        } else {
          _showPlaceholderDialog('No processed text available.');
        }

      case 'retake':
        try {
          DocumentScannerOptions documentOptions = DocumentScannerOptions(
            documentFormat: DocumentFormat.jpeg,
            mode: ScannerMode.filter,
            pageLimit: 1,
            isGalleryImport: true,
          );
          final documentScanner = DocumentScanner(options: documentOptions);
          DocumentScanningResult result = await documentScanner.scanDocument();
          final images = result.images;
          if (images.isNotEmpty) {
            setState(() {
              widget.pathImage[index] = images[0];
              if (detectionResults.length > index) {
                detectionResults[index] = null;
              }
            });
            BrailleDetectionResult newResult =
                await BrailleApiClient.detectBraille(File(images[0]));
            setState(() {
              detectionResults[index] = newResult;
            });
          }
        } catch (e) {
          _showPlaceholderDialog('Failed to retake image: $e');
        }
        break;

      case 'delete':
        setState(() {
          widget.pathImage.removeAt(index);
          detectionResults.removeAt(index);
        });
        break;
    }
  }

  void _showPlaceholderDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _detectTextsForAllImages() async {
    if (isProcessing) return;
    setState(() {
      isProcessing = true;
      _abortRequested = false;
      _abortOpen = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Processing...'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _abortRequested = true;
                      _abortOpen = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Abort Processing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    List<BrailleDetectionResult?> results = [];
    for (int i = 0; i < widget.pathImage.length; i++) {
      if (_abortRequested) {
        break;
      }
      try {
        File imageFile = File(widget.pathImage[i]);
        BrailleDetectionResult result =
            await BrailleApiClient.detectBraille(imageFile);
        results.add(result);
      } catch (e) {
        print('Error detecting braille for image $i: $e');
        results.add(null);
      }
    }
    setState(() {
      detectionResults = results;
      isProcessing = false;
    });
    if (_abortOpen) {
      Navigator.of(context).pop();
    }
    if (_abortRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing aborted'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing complete'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Book Preview',
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 30,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) async {
              switch (value) {
                case 'add_pages':
                  try {
                    DocumentScannerOptions documentOptions =
                        DocumentScannerOptions(
                      documentFormat: DocumentFormat.jpeg,
                      mode: ScannerMode.filter,
                      pageLimit: 100,
                      isGalleryImport: true,
                    );
                    final documentScanner =
                        DocumentScanner(options: documentOptions);
                    DocumentScanningResult result =
                        await documentScanner.scanDocument();
                    final newImages = result.images;
                    setState(() {
                      widget.pathImage.addAll(newImages);
                      detectionResults
                          .addAll(List.filled(newImages.length, null));
                    });
                  } catch (e) {
                    _showPlaceholderDialog('Failed to add pages: $e');
                  }
                  break;

                case 'save_book':
                  _showSaveBookDialog();
                  break;

                case 'discard':
                  Navigator.of(context).pop();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_pages',
                child: Text('Add pages'),
              ),
              const PopupMenuItem(
                value: 'save_book',
                child: Text('Save book'),
              ),
              const PopupMenuItem(
                value: 'discard',
                child: Text(
                  'Discard',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.text_snippet),
                label: const Text(
                  'Detect texts',
                ),
                onPressed: isProcessing ? null : _detectTextsForAllImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.pathImage.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two images per row
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      String imagePath = widget.pathImage[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(imagePath),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _showImageMenu(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
