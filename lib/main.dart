// import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:new_flutter_demo/pages/book_page.dart';
import 'package:new_flutter_demo/pages/camera_page.dart';
import 'package:new_flutter_demo/pages/home_page.dart';
import 'package:new_flutter_demo/pages/login_page.dart';
import 'package:new_flutter_demo/pages/profile_page.dart';
import 'package:new_flutter_demo/pages/setting_page.dart';
import 'package:new_flutter_demo/pages/signup_page.dart';
import 'package:new_flutter_demo/styles/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          navigatorObservers: [routeObserver],
          theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          initialRoute: '/',
          navigatorKey: navigatorKey,
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
            '/book': (context) => const BookPage(),
            '/signup': (context) => const SignupPage(),
            '/profile': (context) => const ProfilePage(),
            '/camera': (context) {
              final args =
                  ModalRoute.of(context)!.settings.arguments as List<String>;
              return CameraPage(pathImage: args);
            },
            '/setting': (context) => SettingPage(isDarkMode: isDarkMode),
          },
        );
      },
    );
  }
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    fontFamily: 'Urbanist',
    scaffoldBackgroundColor: AppColors.bgPrimary,
    primaryColor: Colors.blue,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 30),
    ),
  );
  static final ThemeData darkTheme = ThemeData(
    fontFamily: 'Urbanist',
    scaffoldBackgroundColor: Colors.black54,
    primaryColor: Colors.blueGrey[50],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 30),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        Navigator.of(context).pushReplacementNamed('/book');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
