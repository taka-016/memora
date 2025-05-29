import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const LatLng _pinPosition = LatLng(35.681236, 139.767125); // 東京駅

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Googleマップ')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _pinPosition,
          zoom: 15,
        ),
        markers: {
          const Marker(
            markerId: MarkerId('pin'),
            position: _pinPosition,
            infoWindow: InfoWindow(title: '任意のピン'),
          ),
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MapScreen()));
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
