// coverage:ignore-file
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_verification/presentation/google_map_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_verification/domain/services/location_service.dart';
import 'package:mockito/mockito.dart';
import 'map_screen_test.mocks.dart';
import 'package:flutter_verification/domain/repositories/pin_repository.dart';
import 'package:flutter_verification/domain/entities/pin.dart';

@GenerateMocks([LocationService])
class MockPinRepository implements PinRepository {
  List<Pin> pins = [
    Pin(id: '1', pinId: '1', latitude: 10, longitude: 10),
    Pin(id: '2', pinId: '2', latitude: 20, longitude: 20),
  ];

  @override
  Future<List<Pin>> getPins() async {
    return pins.toList();
  }

  @override
  Future<void> savePin(String pinId, double latitude, double longitude) async {
    pins.add(
      Pin(id: pinId, pinId: pinId, latitude: latitude, longitude: longitude),
    );
  }

  @override
  Future<void> deletePin(String pinId) async {
    pins.removeWhere((pin) => pin.pinId == pinId);
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
                  builder: (_) =>
                      GoogleMapScreen(pinRepository: MockPinRepository()),
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

  // GoogleMapのマーカー追加・削除はWidgetテストで直接検証できないため、UIの存在確認のみ行う

  testWidgets('マーカーをタップすると削除メニュー付きポップアップが表示される', (WidgetTester tester) async {
    // GoogleMapScreenクラスが内部でLoadPinsUseCaseを作成するため、
    // この代わりに初期マーカーをinitialPinsで渡して検証する
    final initialPins = [Pin(id: '1', pinId: '1', latitude: 10, longitude: 10)];
    await tester.pumpWidget(
      MaterialApp(
        home: GoogleMapScreen(
          initialPins: initialPins,
          pinRepository: MockPinRepository(),
        ),
      ),
    );

    // マーカーのFinder（仮: Key('map_marker_0')で1つ目のマーカーを識別）
    final markerFinder = find.byKey(Key('map_marker_0'));
    expect(markerFinder, findsOneWidget);

    // マーカーをタップ
    await tester.tap(markerFinder);
    await tester.pumpAndSettle();

    // ポップアップメニューが表示され、「削除」メニューが存在することを確認
    expect(find.text('削除'), findsOneWidget);
  });
  testWidgets('マップ起動時に保存済みのマーカーが表示される', (WidgetTester tester) async {
    // GoogleMapScreenクラスが内部でLoadPinsUseCaseを作成するため、
    // この代わりに初期マーカーをinitialPinsで渡して検証する
    final initialPins = [Pin(id: '1', pinId: '1', latitude: 10, longitude: 10)];

    // GoogleMapScreenに表示されるマーカー数を確認
    await tester.pumpWidget(
      MaterialApp(
        home: GoogleMapScreen(
          initialPins: initialPins,
          pinRepository: MockPinRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初期マーカーの2つがKey('map_marker_0')とKey('map_marker_1')で表示されることを確認
    expect(find.byKey(Key('map_marker_0')), findsOneWidget);
    expect(find.byKey(Key('map_marker_1')), findsOneWidget);
  });

  testWidgets('現在地ボタンを押すとLocationServiceが呼ばれる', (WidgetTester tester) async {
    final mockService = MockLocationService();
    when(mockService.getCurrentLocation()).thenAnswer(
      (_) async => const CurrentLocation(latitude: 1.0, longitude: 2.0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GoogleMapScreen(
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

  testWidgets('GoogleMapScreenに検索バーが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: GoogleMapScreen(pinRepository: MockPinRepository())),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('場所を検索'), findsOneWidget);
  });
}
