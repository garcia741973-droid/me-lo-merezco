import 'package:flutter/material.dart';

class HelpDetailScreen extends StatelessWidget {

  final String title;
  final String text;

  const HelpDetailScreen({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),

        body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
            text,
            style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            ),
        ),
        ),
    );
  }
}