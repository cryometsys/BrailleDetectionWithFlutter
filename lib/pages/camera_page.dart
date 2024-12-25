import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_flutter_demo/models/book.dart';
import 'package:path_provider/path_provider.dart';

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
    final String pagePath = '${rootDir!.path}/braillify/$bookName/pages';
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
    await saveImages(bookName);
    Book newBook = Book(
      name: bookName,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('books')
        .doc(bookName)
        .set(newBook.toMap());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document Saved'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
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
