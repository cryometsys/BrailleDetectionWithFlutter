import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:new_flutter_demo/styles/app_colors.dart';
import 'package:new_flutter_demo/services/database_services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool hidden = true;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  var auth = FirebaseAuth.instance;
  DatabaseService dbService = DatabaseService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

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
        msg: "Password field cannot be empty",
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
          await dbService.loginUser(email, password);
      if(userCredential != null) {
        if(rememberMe) {
          await _storage.write(key: 'uid', value: userCredential.user?.uid);
          await dbService.storeUserCredentials(email, password);
        }
      }
      Navigator.of(context).pushReplacementNamed('/book');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Fluttertoast.showToast(
          msg: "User does not exist",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else if (e.code == 'wrong-password') {
        Fluttertoast.showToast(
          msg: "Wrong password",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: "An error occurred. Please try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
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
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Login to continue',
                  style: TextStyle(color: Colors.white),
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
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  focusNode: _focusNode,
                  obscureText: hidden,
                  controller: passwordController,
                  decoration: InputDecoration(
                    suffixIcon: _focusNode.hasFocus
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                hidden = !hidden;
                              });
                            },
                            icon: Icon(
                                hidden
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.primaryBlue),
                          )
                        : null,
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.black12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.7),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 207,
                          child: CheckboxListTile(
                            title: const Text("Remember Me",
                                style: TextStyle(color: Colors.white)),
                            value: rememberMe,
                            onChanged: (bool? value) {
                              setState(() {
                                rememberMe = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: AppColors.primaryBlue,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushReplacementNamed('/forgot-password');
                          },
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.blue[800]),
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff102C57),
                        foregroundColor: Colors.white),
                    onPressed: _handleLogin,
                    child: const Text(
                      'LOGIN',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  const Text("Don't have an account?",
                      style: TextStyle(
                        color: Colors.white,
                      )),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/signup');
                    },
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                          color: Colors.blue[800],
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ]),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}