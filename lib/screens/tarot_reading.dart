
import 'package:flutter/material.dart';

class TarotReadingScreen extends StatelessWidget {
  const TarotReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择一张牌'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // This is a placeholder for the card selection UI
            ElevatedButton(
              onPressed: () {
                // Pop with a sample result
                Navigator.of(context).pop('命运之轮');
              },
              child: const Text('选择“命运之轮”'),
            ),
          ],
        ),
      ),
    );
  }
}
