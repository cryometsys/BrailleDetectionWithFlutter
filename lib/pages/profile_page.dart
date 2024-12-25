import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:new_flutter_demo/pages/navbar.dart';
import 'package:new_flutter_demo/services/database_services.dart';
import 'package:new_flutter_demo/styles/app_colors.dart';
import 'package:new_flutter_demo/models/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService dbService = DatabaseService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  Users? currentUser;

  // final String initialName = "Bornil Chowdhury";
  // final String initialEmail = "bornil@gmail.com";
  bool isChanged = false;
  String? selectedGender;
  DateTime? birthDate;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    // firstNameController.text = initialName;
    // emailController.text = initialEmail;
    firstNameController.addListener(_checkForChanges);
    lastNameController.addListener(_checkForChanges);
    emailController.addListener(_checkForChanges);
    currentPasswordController.addListener(_checkForChanges);
    newPasswordController.addListener(_checkForChanges);
    confirmPasswordController.addListener(_checkForChanges);
  }

  Future<void> fetchUserData() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser; // Get current Firebase user
    if(firebaseUser != null) print("The value is:${firebaseUser.uid}");
    else print("The user not found");
    // if (firebaseUser != null) {
    //   currentUser = await dbService.getUserData(firebaseUser.uid); // Fetch user data from Firestore
    //   setState(() {
    //     firstNameController.text = currentUser?.firstName ?? '';
    //     lastNameController.text = currentUser?.lastName ?? '';
    //     emailController.text = currentUser?.mail ?? '';
    //     selectedGender = currentUser?.gender;
    //     birthDate = currentUser?.birthDate?.toDate(); // Convert Timestamp to DateTime if available
    //   });
    // }
  }

  void _checkForChanges() {
    setState(() {
      isChanged = firstNameController.text != currentUser?.firstName ||
          lastNameController.text != currentUser?.lastName ||
          emailController.text != currentUser?.mail ||
          selectedGender != currentUser?.gender ||
          birthDate != currentUser?.birthDate?.toDate() ||
          currentPasswordController.text.isNotEmpty ||
          newPasswordController.text.isNotEmpty ||
          confirmPasswordController.text.isNotEmpty;
    });
  }

  Future<void> _saveChanges() async {
    if (currentUser != null) {
      Users updatedUser = currentUser!.copyWith(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        mail: emailController.text,
        gender: selectedGender,
        birthDate: birthDate != null ? Timestamp.fromDate(birthDate!) : null,
        updatedOn: Timestamp.now(),
      );

      await dbService.updateUserData(FirebaseAuth.instance.currentUser!.uid, updatedUser);
      Fluttertoast.showToast(msg: "Profile updated successfully");
      setState(() {
        isChanged = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double scrHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      drawer: const Navbar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: scrHeight * 0.1,
        title: const Text(
          'PROFILE',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 70,
                      backgroundImage: AssetImage('assets/temp/user1.jpg'),
                    ),
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'First Name',
                style: TextStyle(fontSize: 16),
              ),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'First Name',
                style: TextStyle(fontSize: 16),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Email', style: TextStyle(fontSize: 16)),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Others']
                    .map((gender) => DropdownMenuItem(
                          value: gender.toLowerCase(),
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                  _checkForChanges();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(birthDate != null
                      ? "${birthDate!.day}/${birthDate!.month}/${birthDate!.year}"
                      : "Select Birth Date"),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: birthDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          birthDate = pickedDate;
                        });
                        _checkForChanges(); // Check for changes when selecting date
                      }
                    },
                  ),
                ],
              ),
              const Text('Current Password', style: TextStyle(fontSize: 16)),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your current password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text('New Password', style: TextStyle(fontSize: 16)),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your new password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Confirm New Password',
                  style: TextStyle(fontSize: 16)),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirm your new password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: isChanged ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
