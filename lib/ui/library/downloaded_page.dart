import 'package:flutter/material.dart';

class DownloadedPage extends StatelessWidget {
  const DownloadedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Downloaded Songs (Coming Soon)",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
