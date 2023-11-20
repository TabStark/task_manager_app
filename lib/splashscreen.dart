import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

class splashScreen extends StatefulWidget {
  const splashScreen({super.key});

  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  @override
  void initState() {
    Timer(Duration(seconds: 5), () {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(),
          ));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          color: Theme.of(context).primaryColorLight,
          child: const Center(
              child: Text(
            "Task Manager App",
            style: TextStyle(color: Colors.white, fontSize: 22),
          ))),
    );
  }
}
