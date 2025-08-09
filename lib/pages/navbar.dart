import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:new_flutter_demo/services/database_services.dart';
import 'package:new_flutter_demo/styles/app_colors.dart';

class Navbar extends StatelessWidget {
  final String name;
  final String mail;
  const Navbar({
    super.key,
    required this.name,
    required this.mail,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: Text(mail),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryBlue,
                  ),
                  otherAccountsPictures: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                ListTile(
                  leading: const Icon(Icons.book),
                  title: const Text('Books'),
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/book') {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/book');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                const Divider(
                  height: 1,
                  indent: 15,
                  endIndent: 15,
                  thickness: 1,
                  color: Colors.black12,
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    if (ModalRoute.of(context)?.settings.name != '/profile') {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/profile', arguments: {
                        'name': name, 'mail': mail,
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/setting', arguments: {
                      'name': name, 'mail': mail,
                    });
                  },
                ),
                const Divider(
                  height: 1,
                  indent: 15,
                  endIndent: 15,
                  thickness: 1,
                  color: Colors.black12,
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app_outlined),
                  title: const Text('Logout'),
                  onTap: () async {
                    await dbService.logoutUser();
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 30),
            child: Text(
              'BRAILLIFY@2023',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black26,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
