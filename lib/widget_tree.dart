import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rcz/pages/login_screen.dart';
import 'package:rcz/pages/register_screen.dart';
import 'package:rcz/pages/tasklist_screen.dart';

class WidgetTree extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/auth': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/tasklist': (context) => TaskListScreen(
          user: FirebaseAuth.instance.currentUser,
        ),
      },
    );
  }
}
