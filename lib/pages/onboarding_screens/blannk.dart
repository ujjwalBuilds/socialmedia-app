import 'package:flutter/material.dart';

class Blannk extends StatefulWidget {
  const Blannk({super.key});

  @override
  State<Blannk> createState() => _BlannkState();
}

class _BlannkState extends State<Blannk> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text('hello' , style: TextStyle(color: Colors.white , fontSize: 22),),
      ),
    );
  }
}