import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/time/app_date_time.dart';

void main() {
  group('AppDateTime', () {
    test('日付入力値をUTCの日付として正規化する', () {
      final result = AppDateTime.dateOnlyUtc(DateTime(2026, 5, 14, 23, 59));

      expect(result, DateTime.utc(2026, 5, 14));
      expect(result.isUtc, isTrue);
    });

    test('年月入力値をUTCの月初として正規化する', () {
      final result = AppDateTime.monthStartUtc(DateTime(2026, 5, 31, 23, 59));

      expect(result, DateTime.utc(2026, 5));
      expect(result.isUtc, isTrue);
    });

    test('ローカル日付と時刻をUTCの日時へ変換する', () {
      final result = AppDateTime.localDateAndTimeToUtc(
        DateTime.utc(2026, 5, 14),
        const TimeOfDay(hour: 9, minute: 30),
      );

      expect(result.isUtc, isTrue);
      expect(result, DateTime(2026, 5, 14, 9, 30).toUtc());
    });

    test('UTC日時を表示用のローカル日付へ変換する', () {
      final utc = DateTime.utc(2026, 5, 14, 9, 30);

      final result = AppDateTime.localDateFromUtc(utc);

      final local = utc.toLocal();
      expect(result, DateTime(local.year, local.month, local.day));
      expect(result.isUtc, isFalse);
    });
  });
}
