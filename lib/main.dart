import 'package:flutter/material.dart';
import 'package:parktixspaceadmin/services/authservice.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    theme: ThemeData(
      primaryColor: Colors.blue.shade800
    ),
    title: 'ParkTix',
    debugShowCheckedModeBanner: false,
    home: AuthService().handleAuth(),
  ));
}