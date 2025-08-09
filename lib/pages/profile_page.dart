import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  Users? currentUser;

  bool isChanged = false;
  String? selectedGender;
  DateTime? birthDate;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();

    // Listen for changes to enable/disable save button
    firstNameController.addListener(_checkForChanges);
    lastNameController.addListener(_checkForChanges);
    emailController.addListener(_checkForChanges);
    currentPasswordController.addListener(_checkForChanges);
    newPasswordController.addListener(_checkForChanges);
    confirmPasswordController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    // dispose controllers to avoid memory leaks
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      print("No user signed in");
      return;
    }
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        currentUser = Users.fromJson(userDoc.data()! as Map<String, dynamic>);

        setState(() {
          firstNameController.text = currentUser?.firstName ?? '';
          lastNameController.text = currentUser?.lastName ?? '';
          emailController.text = currentUser?.mail ?? '';
          selectedGender = currentUser?.gender;
          birthDate = currentUser?.birthDate?.toDate();
          isChanged = false; // Reset change state after loading
        });
      } else {
        print("User document does not exist");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void _checkForChanges() {
    setState(() {
      isChanged = firstNameController.text != (currentUser?.firstName ?? '') ||
          lastNameController.text != (currentUser?.lastName ?? '') ||
          emailController.text != (currentUser?.mail ?? '') ||
          selectedGender != currentUser?.gender ||
          birthDate != currentUser?.birthDate?.toDate() ||
          currentPasswordController.text.isNotEmpty ||
          newPasswordController.text.isNotEmpty ||
          confirmPasswordController.text.isNotEmpty;
    });
  }

  Future<void> _saveChanges() async {
    if (currentUser == null) {
      Fluttertoast.showToast(msg: "No user data loaded yet");
      return;
    }
    Users updatedUser = currentUser!.copyWith(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      mail: emailController.text.trim(),
      gender: selectedGender,
      birthDate: birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      updatedOn: Timestamp.now(),
    );

    try {
      await dbService.updateUserData(FirebaseAuth.instance.currentUser!.uid, updatedUser);

      Fluttertoast.showToast(msg: "Profile updated successfully");

      setState(() {
        currentUser = updatedUser;
        isChanged = false;

        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to update profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double scrHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      drawer: Navbar(
        name: currentUser?.firstName ?? '',
        mail: currentUser?.mail ?? '',
      ),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('First Name', style: TextStyle(fontSize: 16)),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                hintText: 'Enter your first name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Last Name', style: TextStyle(fontSize: 16)),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                hintText: 'Enter your last name',
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
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: ['male', 'female', 'others']
                  .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender[0].toUpperCase() + gender.substring(1)),
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
                Expanded(
                  child: Text(
                    birthDate != null
                        ? "${birthDate!.day}/${birthDate!.month}/${birthDate!.year}"
                        : "Select Birth Date",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime initialDate = birthDate ?? DateTime(1990, 1, 1);
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        birthDate = pickedDate;
                      });
                      _checkForChanges();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            const Text('Confirm New Password', style: TextStyle(fontSize: 16)),
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
                onPressed: isChanged ? _saveChanges : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
