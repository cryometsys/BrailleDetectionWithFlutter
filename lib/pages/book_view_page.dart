import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../styles/app_colors.dart';

class BookViewPage extends StatefulWidget {
  final String bookTitle;
  final String bookId;
  final List<String> pages;
  final List<String> images;
  final List<String> maps;
  final List<String> explanations;

  const BookViewPage(
      {super.key,
      required this.bookTitle,
      required this.pages,
      required this.images,
      required this.maps,
      required this.explanations, required this.bookId});

  @override
  State<BookViewPage> createState() => _BookViewPageState();
}

class _BookViewPageState extends State<BookViewPage> {
  int currentPageIndex = 0;
  late String _currentBookTitle;

  TextEditingController nameController = TextEditingController();
  TextEditingController pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentBookTitle = widget.bookTitle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentBookTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'back':
                  break;
                case 'add_page':
                  break;
                case 'change_name':
                  _showChangeNamePopup();
                  break;
                case 'share':
                  _showShareOptionsPopup();
                  break;
                case 'delete_book':
                  _confirmAndDeleteBook();
                  break;
                case 'search_page':
                  _showSearchPagePopup();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'change_name',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Change Name'),
                      Icon(Icons.edit),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'search_page',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Search Page'),
                      Icon(Icons.search_rounded),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'share',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Share'),
                      Icon(Icons.share),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'back',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Close Menu'),
                      Icon(Icons.close), // Back icon
                    ],
                  ),
                ),
                const PopupMenuDivider(
                  height: 2,
                ),
                const PopupMenuItem<String>(
                  value: 'delete_book',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delete Book',
                        style: TextStyle(color: Colors.red),
                      ),
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: widget.pages.length,
              onPageChanged: (index) {
                setState(() {
                  currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.pages[currentPageIndex],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Page ${currentPageIndex + 1} / ${widget.pages.length}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
            child: Center(
              child: ElevatedButton(
                onPressed: _showPageOptionsSheet,
                child: const Text("Page Options"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPageOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSheetOption('View Image', Icons.image, () {
                  Navigator.pop(context);
                  _showImagePopup();
                }),
                _buildSheetOption('View Image Mapping', Icons.map, () {
                  Navigator.pop(context);
                  _showImageMappingPopup();
                }),
                _buildSheetOption('View AI Explanation', Icons.psychology, () {
                  Navigator.pop(context);
                  _showAIExplanationPopup();
                }),
                _buildSheetOption('Delete Image', Icons.delete_outline, () {
                  Navigator.pop(context);
                  _deleteImage();
                }, color: Colors.red),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption(String title, IconData icon, VoidCallback onTap,
      {Color? color}) {
    final giveColor = color ?? Colors.black;
    return ListTile(
      leading: Icon(
        icon,
        color: giveColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: giveColor),
      ),
      onTap: onTap,
    );
  }

  void _showChangeNamePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: _currentBookTitle,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.secondaryBlue,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                //local storage change
                final Directory? rootDir = await getExternalStorageDirectory();
                final oldBookDir = Directory('${rootDir?.path}/braillify/$_currentBookTitle');
                final newBookDir = Directory('${rootDir?.path}/braillify/$newName');
                if (await oldBookDir.exists()) {
                  await oldBookDir.rename(newBookDir.path);
                }

                //firebase change
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User not logged in'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final booksRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('books');
                try {
                  final existingBooks = await booksRef.where('name', isEqualTo: newName).get();

                  if (existingBooks.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Book name already exists'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  await booksRef.doc(widget.bookId).update({
                    'name': newName,
                    'modifiedAt': DateTime.now(),
                  });

                  setState(() {
                    _currentBookTitle = newName;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book name changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.of(context).pop(); // Close the dialog
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error changing book name: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            )

          ],
        );
      },
    );
  }

  void _showSearchPagePopup() {
    pageController.text = (currentPageIndex + 1).toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Go To Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pageController,
                decoration:
                    const InputDecoration(hintText: "Enter page number"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.secondaryBlue,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                int? pageNumber = int.tryParse(pageController.text);
                if (pageNumber != null &&
                    pageNumber > 0 &&
                    pageNumber <= widget.pages.length) {
                  setState(() {
                    currentPageIndex = pageNumber - 1;
                  });
                  Navigator.of(context).pop();
                } else {}
              },
              child: const Text(
                'Go',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Future<void> _confirmAndDeleteBook() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Book'),
          content: const Text('Are you sure you want to delete this book? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
        );
        return;
      }
      final String oldBookName = _currentBookTitle;
      final String bookId = widget.bookId;

      // Firestore references
      final bookRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('books')
          .doc(bookId);

      try {
        final pagesSnapshot = await bookRef.collection('pages').get();
        for (final doc in pagesSnapshot.docs) {
          await doc.reference.delete();
        }
        await bookRef.delete();

        // Delete local storage folder
        final Directory? rootDir = await getExternalStorageDirectory();
        if (rootDir != null) {
          final oldBookDir = Directory('${rootDir.path}/braillify/$oldBookName');
          if (await oldBookDir.exists()) {
            await oldBookDir.delete(recursive: true);
            print('Local storage folder deleted successfully');
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book deleted successfully'), backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting book: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  void _showShareOptionsPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share Options'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    print("Share on Facebook");
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.facebook, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Facebook"),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    print("Share on Twitter");
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.new_label, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Twitter"),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    print("Share on WhatsApp");
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.new_label, color: Colors.green),
                      SizedBox(width: 8),
                      Text("WhatsApp"),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    print("Share via Gmail");
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Gmail"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  //Page Option Functions
  void _showImageMappingPopup() {
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
                File(widget.maps[currentPageIndex]),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePopup() {
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
                File(widget.images[currentPageIndex]),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAIExplanationPopup() {
    final explanationText = (widget.explanations.length > currentPageIndex)
        ? widget.explanations[currentPageIndex]
        : '(No explanation available)';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Explanation'),
        content: SingleChildScrollView(
          child: Text(explanationText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteImage() async {
    if (currentPageIndex < 0 || currentPageIndex >= widget.pages.length) return;

    //Delete image file
    try {
      final imageFile = File(widget.images[currentPageIndex]);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print('Error deleting image file: $e');
    }

    // Delete annotated image file
    try {
      final mapFile = File(widget.maps[currentPageIndex]);
      if (await mapFile.exists()) {
        await mapFile.delete();
      }
    } catch (e) {
      print('Error deleting map file: $e');
    }

    final Directory? rootDir = await getExternalStorageDirectory();
    if (rootDir == null) return;

    final String bookName = widget.bookTitle;
    // Build paths for page text and explanation files
    final pageFilePath =
        '${rootDir.path}/braillify/$bookName/pages/page${currentPageIndex + 1}.txt';
    final explFilePath =
        '${rootDir.path}/braillify/$bookName/expl/expl${currentPageIndex + 1}.txt';

    //Page delete
    try {
      final pageFile = File(pageFilePath);
      if (await pageFile.exists()) {
        await pageFile.delete();
      }
    } catch (e) {
      print('Error deleting page text file: $e');
    }

    //Explanation delete
    try {
      final explFile = File(explFilePath);
      if (await explFile.exists()) {
        await explFile.delete();
      }
    } catch (e) {
      print('Error deleting explanation file: $e');
    }

    //Firebase data delete
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final pageNumber = 'page${currentPageIndex + 1}';
    final bookRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('books')
        .doc(bookName);

    try {
      await bookRef.collection('pages').doc(pageNumber).delete();
      if (currentPageIndex == 0) {
        await bookRef.delete();
        print("Book document deleted because no pages remain.");
      }
    } catch (e) {
      print('Error deleting page from Firestore: $e');
    }

    setState(() {
      widget.images.removeAt(currentPageIndex);
      widget.pages.removeAt(currentPageIndex);
      widget.maps.removeAt(currentPageIndex);
      widget.explanations.removeAt(currentPageIndex);

      if (currentPageIndex >= widget.pages.length && currentPageIndex > 0) {
        currentPageIndex--;
      }
    });
    if (widget.pages.isEmpty) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    }
  }
}
