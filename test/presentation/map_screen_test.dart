// coverage:ignore-file
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verification/presentation/map_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_verification/domain/services/location_service.dart';
import 'package:mockito/mockito.dart';
import 'map_screen_test.mocks.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';
import 'package:flutter_verification/domain/entities/pin.dart';

@GenerateMocks([LocationService])
class MockPinRepository implements PinRepository {
  List<LatLng> pins = [const LatLng(10, 10), const LatLng(20, 20)];

  @override
  Future<List<Pin>> getPins() async {
    return pins
        .asMap()
        .entries
        .map(
          (e) => Pin(
            id: e.key.toString(),
            latitude: e.value.latitude,
            longitude: e.value.longitude,
          ),
        )
        .toList();
  }

  @override
  Future<void> savePin(LatLng position) async {
    pins.add(position);
  }
}

class TestMyHomePage extends StatelessWidget {
  final String title;
  const TestMyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          ListTile(
            title: const Text('マップ表示'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MapScreen(pinRepository: MockPinRepository()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class TestMyApp extends StatelessWidget {
  const TestMyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const TestMyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

void main() {
  testWidgets('マップ表示メニューをタップするとGoogleMap画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const TestMyApp());

    // 「マップ表示」メニューをタップ
    await tester.tap(find.text('マップ表示'));
    await tester.pumpAndSettle();

    // AppBarタイトル確認
    expect(find.text('Googleマップ'), findsOneWidget);

    // GoogleMapウィジェットが存在することを確認
    expect(find.byType(GoogleMap), findsOneWidget);
  });

  testWidgets('マップ画面に現在地ボタンが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const TestMyApp());
    await tester.tap(find.text('マップ表示'));
    await tester.pumpAndSettle();

    // 現在地ボタン（FloatingActionButton）が存在すること
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });

  // GoogleMapのピン追加・削除はWidgetテストで直接検証できないため、UIの存在確認のみ行う

  testWidgets('ピンをタップすると削除メニュー付きポップアップが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          initialPins: [LatLng(0, 0)],
          pinRepository: MockPinRepository(),
        ),
      ),
    );

    // ピンのFinder（仮: Key('map_pin_0')で1つ目のピンを識別）
    final pinFinder = find.byKey(Key('map_pin_0'));
    expect(pinFinder, findsOneWidget);

    // ピンをタップ
    await tester.tap(pinFinder);
    await tester.pumpAndSettle();

    // ポップアップメニューが表示され、「削除」メニューが存在することを確認
    expect(find.text('削除'), findsOneWidget);
  });
  testWidgets('マップ起動時に保存済みのピンが表示される', (WidgetTester tester) async {
    // MapScreenクラスが内部でLoadPinsUseCaseを作成するため、
    // この代わりに初期ピンをinitialPinsで渡して検証する
    final initialPins = [LatLng(35.68, 139.76), LatLng(34.67, 135.52)];

    // MapScreenに表示されるピン数を確認
    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          initialPins: initialPins,
          pinRepository: MockPinRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初期ピンの2つがKey('map_pin_0')とKey('map_pin_1')で表示されることを確認
    expect(find.byKey(Key('map_pin_0')), findsOneWidget);
    expect(find.byKey(Key('map_pin_1')), findsOneWidget);
  });

  testWidgets('現在地ボタンを押すとLocationServiceが呼ばれる', (WidgetTester tester) async {
    final mockService = MockLocationService();
    when(mockService.getCurrentLocation()).thenAnswer(
      (_) async => const CurrentLocation(latitude: 1.0, longitude: 2.0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MapScreen(
          locationService: mockService,
          pinRepository: MockPinRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 現在地ボタンをタップ
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pumpAndSettle();

    // LocationService.getCurrentLocationが呼ばれたことを検証
    verify(mockService.getCurrentLocation()).called(1);
  });
}
