import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:chatvenenoso/Canales.dart';
import 'package:chatvenenoso/screens/signin_screen.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat con Firebase',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: SignInScreen(),
    );
  }
}
