import 'dart:io';
import 'package:flutter/material.dart';
import '../styles/app_colors.dart';

class BookViewPage extends StatefulWidget {
  final String bookTitle;
  final List<String> pages;
  final List<String> images;

  const BookViewPage(
      {super.key,
      required this.bookTitle,
      required this.pages,
      required this.images});

  @override
  State<BookViewPage> createState() => _BookViewPageState();
}

class _BookViewPageState extends State<BookViewPage> {
  int currentPageIndex = 0;

  TextEditingController nameController = TextEditingController();
  TextEditingController pageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle),
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
                case 'grid_view':
                  break;
                case 'share':
                  _showShareOptionsPopup();
                  break;
                case 'delete_book':
                  break;
                case 'search_page':
                  _showSearchPagePopup();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'add_page',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add Page'),
                      Icon(Icons.add_circle_outline_outlined),
                    ],
                  ),
                ),
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
                  value: 'grid_view',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Grid View'),
                      Icon(Icons.grid_view),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showImagePopup();
                  },
                  child: const Text("View Image"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Delete Image"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Read Image"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(widget.images[currentPageIndex]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                )
              ],
            ),
          ),
        );
      },
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
                  hintText: widget.bookTitle,
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
              onPressed: () {
                // Implement save logic here
                print("Name changed to ${nameController.text}");
                Navigator.of(context).pop();
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
}
