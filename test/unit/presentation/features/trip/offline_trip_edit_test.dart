import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/location_providers.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/features/trip/trip_edit_modal.dart';
import 'package:memora/presentation/features/trip/itinerary_item_edit_bottom_sheet.dart';
import 'package:memora/presentation/shared/map_views/placeholder_map_view_builder.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  final clock = FixedAppClock(DateTime(2026, 5, 15));
  Widget app(Widget child) => ProviderScope(
    overrides: [
      appModeProvider.overrideWithValue(AppMode.offline),
      appClockProvider.overrideWithValue(clock),
      mapViewBuilderProvider.overrideWith(
        (ref) => throw TestException('地図を解決しない'),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );

  testWidgets('オフラインの旅行編集は地図を解決せず場所なしで保存できる', (tester) async {
    TripEntryDto? saved;
    await tester.pumpWidget(
      app(
        TripEditModal(
          groupId: 'group',
          groupMembers: const [],
          year: 2026,
          onSave: (trip) async {
            saved = trip;
            return true;
          },
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('訪問場所'), findsNothing);
    await tester.tap(find.text('作成'));
    await tester.pump();
    expect(saved, isNotNull);
    expect(saved!.locations, isEmpty);
  });

  testWidgets('オフラインの旅程編集は場所選択を表示せず予定を保存できる', (tester) async {
    ItineraryItemDto? saved;
    await tester.pumpWidget(
      app(
        ItineraryItemEditBottomSheet(
          item: const ItineraryItemDto(id: 'item', tripId: 'trip', name: '出発'),
          groupId: 'group',
          clock: clock,
          mapViewBuilder: const PlaceholderMapViewBuilder(),
          onLocationCreated: (location) async => location,
          onSaved: (item) {
            saved = item;
          },
        ),
      ),
    );
    expect(find.text('訪問場所'), findsNothing);
    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(saved?.name, '出発');
    expect(saved?.locationId, isNull);
    expect(tester.takeException(), isNull);
  });
}
