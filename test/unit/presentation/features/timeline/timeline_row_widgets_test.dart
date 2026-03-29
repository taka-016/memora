import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/dvc_row.dart';
import 'package:memora/presentation/features/timeline/group_event_row.dart';
import 'package:memora/presentation/features/timeline/member_row.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/trip_row.dart';

void main() {
  group('TimelineRowWidgets', () {
    testWidgets('TripRowは対象年の旅行を表示してタップ時に対象年を通知する', (
      WidgetTester tester,
    ) async {
      int? selectedYear;

      await tester.pumpWidget(
        _wrap(
          TripRow(
            years: const [2025],
            tripsByYear: {
              2025: [
                TripEntryDto(
                  id: 'trip-1',
                  groupId: 'group-1',
                  tripYear: 2025,
                  tripName: '北海道旅行',
                  tripStartDate: DateTime(2025, 8, 15),
                ),
              ],
            },
            rowHeight: 100,
            yearColumnWidth: 120,
            buttonColumnWidth: 100,
            borderColor: Colors.grey,
            borderWidth: 1,
            onYearSelected: (year) {
              selectedYear = year;
            },
          ),
        ),
      );

      expect(find.text('北海道旅行'), findsOneWidget);
      expect(find.text('2025/08/15'), findsOneWidget);

      await tester.tap(find.text('北海道旅行'));
      await tester.pumpAndSettle();

      expect(selectedYear, 2025);
    });

    testWidgets('GroupEventRowは対象年セルのキーを維持して編集通知を返す', (
      WidgetTester tester,
    ) async {
      int? selectedYear;

      await tester.pumpWidget(
        _wrap(
          GroupEventRow(
            years: const [2025],
            eventsByYear: {
              2025: const GroupEventDto(
                id: 'event-1',
                groupId: 'group-1',
                year: 2025,
                memo: '運動会',
              ),
            },
            rowHeight: 100,
            yearColumnWidth: 120,
            buttonColumnWidth: 100,
            borderColor: Colors.grey,
            borderWidth: 1,
            onYearSelected: (year) {
              selectedYear = year;
            },
          ),
        ),
      );

      expect(find.byKey(const Key('group_event_cell_2025')), findsOneWidget);
      expect(find.text('運動会'), findsOneWidget);

      await tester.tap(find.byKey(const Key('group_event_cell_2025')));
      await tester.pumpAndSettle();

      expect(selectedYear, 2025);
    });

    testWidgets('DvcRowは対象年セルのキーを維持して詳細表示通知を返す', (WidgetTester tester) async {
      int? selectedYear;

      await tester.pumpWidget(
        _wrap(
          DvcRow(
            years: const [2025],
            usagesByYear: {
              2025: [
                DvcPointUsageDto(
                  id: 'usage-1',
                  groupId: 'group-1',
                  usageYearMonth: DateTime(2025, 4),
                  usedPoint: 120,
                  memo: '春休み',
                ),
              ],
            },
            rowHeight: 100,
            yearColumnWidth: 120,
            buttonColumnWidth: 100,
            borderColor: Colors.grey,
            borderWidth: 1,
            onYearSelected: (year) {
              selectedYear = year;
            },
          ),
        ),
      );

      expect(
        find.byKey(const Key('dvc_point_usage_cell_2025')),
        findsOneWidget,
      );
      expect(find.text('2025-04  120pt'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dvc_point_usage_cell_2025')));
      await tester.pumpAndSettle();

      expect(selectedYear, 2025);
    });

    testWidgets('MemberRowは表示設定に応じて年齢と学年と厄年を組み立てる', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MemberRow(
            member: GroupMemberDto(
              memberId: 'member-1',
              groupId: 'group-1',
              displayName: 'タロちゃん',
              birthday: DateTime(2000, 6, 1),
              gender: '男性',
            ),
            years: const [2025],
            displaySettings: const TimelineDisplaySettings(
              showAge: true,
              showGrade: true,
              showYakudoshi: true,
            ),
            rowHeight: 100,
            yearColumnWidth: 120,
            buttonColumnWidth: 100,
            borderColor: Colors.grey,
            borderWidth: 1,
            buildSchoolGradeLabel: (_, __) => '高校3年生',
            buildYakudoshiLabel: (_, __, ___) => '本厄',
          ),
        ),
      );

      expect(find.textContaining('25歳'), findsOneWidget);
      expect(find.textContaining('高校3年生'), findsOneWidget);
      expect(find.textContaining('本厄'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 600, height: 200, child: child)),
  );
}
