import 'package:flutter/material.dart';

class ApplicationUnavailablePage extends StatelessWidget {
  const ApplicationUnavailablePage({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('memora')),
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(reason)),
      ),
    );
  }
}
