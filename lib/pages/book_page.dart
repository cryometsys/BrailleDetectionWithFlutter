import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:new_flutter_demo/models/user.dart';
import 'package:new_flutter_demo/pages/camera_page.dart';
import 'package:new_flutter_demo/pages/navbar.dart';
import 'package:new_flutter_demo/styles/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import '../services/database_services.dart';
import 'book_view_page.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  late int userCount;
  String? firstName;
  final DatabaseService dbService = DatabaseService();
  List<String> userBooks = [];
  Map<String, List<String>> bookImages = {};
  List<DateTime> modifiedDates = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Users doc = Users.fromJson(userDoc.data()! as Map<String, dynamic>);
        setState(() {
          firstName = doc.firstName;
        });
        QuerySnapshot booksSnapshot = await userDoc.reference.collection('books').get();
        List<String> books = [];
        List<DateTime> dates = [];
        for (var bookDoc in booksSnapshot.docs) {
          books.add(bookDoc['name']);
          Timestamp timestamp = bookDoc['modifiedAt'];
          dates.add(timestamp.toDate());
        }
        print("The books are: $books");
        setState(() {
          userBooks = books;
          modifiedDates = dates;
        });
        await loadAllBookImages();
      } else {
        print('User document does not exist');
      }
    } else {
      print('No user signed in');
    }
  }


  Future<void> loadAllBookImages() async {
    for (String book in userBooks) {
      List<String> images = await _loadImages(book);
      bookImages[book] = images;
    }
    setState(() {});
  }

  Future<List<String>> _loadPages(String bookTitle) async {
    final rootDir = await getExternalStorageDirectory();
    final bookPath = Directory('${rootDir!.path}/braillify/$bookTitle/pages');
    List<String> pages = [];

    if (await bookPath.exists()) {
      final files = bookPath.listSync();
      if (files.isNotEmpty) {
        for (var file in files) {
          if (file is File && file.path.endsWith('.txt')) {
            String content = await file.readAsString();
            pages.add(content);
          }
        }
      }
    } else {
      Fluttertoast.showToast(
        msg: "The book does not exist.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    return pages;
  }

  Future<List<String>> _loadImages(String bookTitle) async {
    final rootDir = await getExternalStorageDirectory();
    final imgPath = Directory('${rootDir!.path}/braillify/$bookTitle/img');
    List<String> imagePaths = [];

    if (await imgPath.exists()) {
      final files = imgPath.listSync();
      if (files.isNotEmpty) {
        for (var file in files) {
          if (file is File &&
              (file.path.endsWith('.jpg') ||
                  file.path.endsWith('.png') ||
                  file.path.endsWith('.jpeg'))) {
            imagePaths.add(file.path);
          }
        }
        imagePaths.sort((a, b) {
          String nameA = a.split('/').last;
          String nameB = b.split('/').last;
          return nameA.compareTo(nameB);
        });
      }
    }

    return imagePaths;
  }

  Widget _userItem(String bookTitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 25),
      child: ElevatedButton(
        onPressed: () async {
          List<String> pages = await _loadPages(bookTitle);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BookViewPage(
                bookTitle: bookTitle,
                pages: pages.isNotEmpty ? pages : ["No content available."],
                images: bookImages[bookTitle] ?? []),
          ));
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            const Color(0xffFAF6E3),
          ),
          shape: WidgetStateProperty.all<OutlinedBorder>(
              const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(15.0),
            ),
          )),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: bookImages[bookTitle]?.isNotEmpty == true
                  ? Image.file(
                      File(bookImages[bookTitle]![0]),
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/temp/bookTemp.webp',
                      height: 80,
                      width: 80,
                    ),
            ),
            const Spacer(),
            Column(
              children: [
                Text(
                  bookTitle,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Last Modified: 01/01/1111",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff2A3663),
                  ),
                )
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double scrHeight = MediaQuery.of(context).size.height;
    return RefreshIndicator(
      onRefresh: fetchUserData,
      child: Scaffold(
        drawer: const Navbar(),
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              floating: true,
              expandedHeight: scrHeight * .2,
              backgroundColor: AppColors.primaryBlue,
              automaticallyImplyLeading: false,
              leading: Builder(builder: (BuildContext context) {
                return IconButton(
                  iconSize: 35,
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                  ),
                );
              }),
              flexibleSpace: FlexibleSpaceBar(
                title: Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $firstName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Book number: ${userBooks.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                titlePadding: EdgeInsets.zero,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return _userItem(userBooks[index]);
                },
                childCount: userBooks.length,
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FloatingActionButton(
            onPressed: () async {
              DocumentScannerOptions documentOptions = DocumentScannerOptions(
                documentFormat: DocumentFormat.jpeg,
                mode: ScannerMode.filter,
                pageLimit: 100,
                isGalleryImport: true,
              );
              final documentScanner = DocumentScanner(options: documentOptions);
              DocumentScanningResult result =
                  await documentScanner.scanDocument();
              final images = result.images;
              CameraPage(
                pathImage: images,
              );
              await Navigator.pushNamed(
                context,
                '/camera',
                arguments: images,
              );
            },
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
