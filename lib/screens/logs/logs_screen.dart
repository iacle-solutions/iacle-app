import 'package:flutter/material.dart';

/// Logs route. The previous screen file was missing from the tree.
class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Logs'),
      ),
    );
  }
}
