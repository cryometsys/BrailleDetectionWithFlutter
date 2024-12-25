import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:new_flutter_demo/pages/navbar.dart';
import 'package:new_flutter_demo/styles/app_colors.dart';

class SettingPage extends StatefulWidget {
  final ValueNotifier<bool> isDarkMode;

  const SettingPage({super.key, required this.isDarkMode});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final storage = FlutterSecureStorage();
    double scrHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      drawer: const Navbar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: scrHeight * 0.1,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              iconSize: 35,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(
                Icons.menu,
                color: AppColors.primaryBlue,
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Left align items
            children: [
              // Dark Mode Toggle
              const Text('Theme', style: TextStyle(fontSize: 16)),
              SwitchListTile(
                title:
                Text(widget.isDarkMode.value ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                value: widget.isDarkMode.value,
                onChanged: (bool value) {
                  widget.isDarkMode.value = value; // Update the global theme state
                },
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await auth.signOut();
                      await storage.delete(key: 'email');
                      await storage.delete(key: 'password');
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                    style:
                    ElevatedButton.styleFrom(padding:
                    const EdgeInsets.symmetric(vertical:
                    15, horizontal:
                    30),),
                    child: const Text('Sign Out'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                    },
                    style:
                    ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical:
                      15, horizontal:
                      30),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete Account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}