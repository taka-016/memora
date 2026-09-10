import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/providers/location_providers.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/presentation/features/map/map_screen.dart';
import 'package:memora/presentation/features/member/member_edit_modal.dart';
import 'package:memora/presentation/features/setting/settings.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_current_member_notifier.dart';
import '../../../helpers/test_exception.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Widget app(Widget child) => ProviderScope(
    overrides: [
      ...AppCompositionRoot(AppMode.offline).overrides,
      currentMemberNotifierProvider.overrideWith(
        () => FakeCurrentMemberNotifier.loading(),
      ),
      mapViewBuilderProvider.overrideWith(
        (ref) => throw TestException('地図を解決しない'),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('オフラインの地図呼び出しは地図を構築せず利用不可を案内する', (tester) async {
    await tester.pumpWidget(app(const MapScreen()));
    expect(find.text('この機能はオンラインモードで利用できます。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('オフラインではメンバーの招待を表示しない', (tester) async {
    await tester.pumpWidget(
      app(
        MemberEditModal(
          member: const MemberDto(id: 'member', displayName: '家族'),
          onSave: (_) async {},
          onInvite: (_) async {},
        ),
      ),
    );
    expect(find.text('招待'), findsNothing);
    expect(find.text('更新'), findsOneWidget);
  });

  testWidgets('設定からオフラインの保存先とデータ消失条件を確認できる', (tester) async {
    await tester.pumpWidget(app(const Settings()));
    await tester.pump();
    expect(find.text('オフラインモード'), findsOneWidget);
    expect(find.textContaining('アプリ内部ストレージ'), findsOneWidget);
    expect(find.textContaining('アプリ削除・データ消去・端末故障'), findsOneWidget);
    expect(find.textContaining('地図・場所検索・現在地・共有・招待は利用できません'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
