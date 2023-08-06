import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rcz/pages/login_screen.dart';
import 'package:rcz/pages/register_screen.dart';
import 'package:rcz/pages/tasklist_screen.dart';
import 'package:rcz/pages/logo_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatefulWidget {
  @override
  _TaskManagerAppState createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  User? _user;
  bool _showLogoScreen = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() async {
    // Simulate a delay to show the logo screen
    await Future.delayed(const Duration(seconds: 2));

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
        _showLogoScreen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget initialScreen;

    if (_showLogoScreen) {
      initialScreen = LogoScreen();
    } else {
      initialScreen = _user == null ? LoginScreen() : TaskListScreen(user: _user);
    }

    return MaterialApp(
      title: 'Task Manager App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: initialScreen,
      routes: {
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}
