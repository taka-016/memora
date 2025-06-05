import 'package:flutter/material.dart';
import 'package:flutter_verification/infrastructure/repositories/firestore_pin_repository.dart';
import 'map_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {
        'title': 'マップ表示',
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  MapScreen(pinRepository: FirestorePinRepository()),
            ),
          );
        },
      },
      {'title': 'ダミー機能A', 'onTap': () {}},
      {'title': 'ダミー機能B', 'onTap': () {}},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('トップメニュー'),
      ),
      body: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return ListTile(
            title: Text(item['title'] as String),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: item['onTap'] as void Function(),
          );
        },
      ),
    );
  }
}
