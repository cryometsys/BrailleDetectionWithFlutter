import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:new_flutter_demo/services/database_services.dart';
import 'package:new_flutter_demo/styles/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController usernameFirstController = TextEditingController();
  final TextEditingController usernameSecondController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  DatabaseService dbService = DatabaseService();


  bool hidden = true;
  bool hiddenConfirm = true;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNodeConfirm = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
    _focusNodeConfirm.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    usernameFirstController.dispose();
    usernameSecondController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _focusNode.dispose();
    _focusNodeConfirm.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    String firstName = usernameFirstController.text.trim();
    String lastName = usernameSecondController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      Fluttertoast.showToast(
        msg: "Name field cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }
    if (email.isEmpty) {
      Fluttertoast.showToast(
        msg: "Email field cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }
    if (password.isEmpty) {
      Fluttertoast.showToast(
        msg: "Password field(s) cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }
    if (confirmPassword.isEmpty) {
      Fluttertoast.showToast(
        msg: "Password field(s) cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }
    if (password != confirmPassword) {
      Fluttertoast.showToast(
        msg: "Passwords do not match",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    try {
      UserCredential? userCredential =
          await dbService.signupUser(email, password);
      if(userCredential != null) {
        await dbService.saveUserData(userCredential, firstName, lastName);
        Navigator.of(context).pushReplacementNamed('/login');
      }
      else {
        Fluttertoast.showToast(msg: "Signup failed. Please try again.", toastLength: Toast.LENGTH_SHORT);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "An error occurred");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const Text(
                  'BRAILLIFY',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 50,
                  ),
                ),
                Container(
                  width: 200,
                  child: Image.asset(
                    'assets/images/braille.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Hello There',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Create a new account',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: usernameFirstController,
                  decoration: InputDecoration(
                    hintText: 'First Nname',
                    hintStyle: const TextStyle(color: Colors.black12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: usernameSecondController,
                  decoration: InputDecoration(
                    hintText: 'Second Name',
                    hintStyle: const TextStyle(color: Colors.black12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email Address',
                    hintStyle: const TextStyle(color: Colors.black12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  focusNode: _focusNode,
                  obscureText: hidden,
                  decoration: InputDecoration(
                    suffixIcon: _focusNode.hasFocus
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                hidden = !hidden;
                              });
                            },
                            icon: Icon(
                              hidden ? Icons.visibility : Icons.visibility_off,
                              color: AppColors.primaryBlue,
                            ),
                          )
                        : null,
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.black12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  controller: passwordController,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  focusNode: _focusNodeConfirm,
                  obscureText: hiddenConfirm,
                  decoration: InputDecoration(
                    suffixIcon: _focusNodeConfirm.hasFocus
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                hiddenConfirm = !hiddenConfirm;
                              });
                            },
                            icon: Icon(
                              hiddenConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.primaryBlue,
                            ),
                          )
                        : null,
                    hintText: 'Confirm Password',
                    hintStyle: const TextStyle(color: Colors.black12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  controller: confirmPasswordController,
                ),
                const SizedBox(
                  height: 30,
                ),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff102C57),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _handleSignup();
                    },
                    child: const Text(
                      'SIGN UP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Or create account with',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google.webp',
                            width: 30,
                            height: 30,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/facebook.webp',
                            width: 30,
                            height: 30,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/github.png',
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.blue[800],
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
