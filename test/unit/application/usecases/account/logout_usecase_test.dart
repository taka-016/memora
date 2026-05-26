import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/usecases/account/logout_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'logout_usecase_test.mocks.dart';

@GenerateMocks([AuthService, AndroidWidgetCacheStorage])
void main() {
  group('LogoutUseCase', () {
    late LogoutUseCase useCase;
    late MockAuthService mockAuthService;
    late MockAndroidWidgetCacheStorage mockAndroidWidgetCacheStorage;

    setUp(() {
      mockAuthService = MockAuthService();
      mockAndroidWidgetCacheStorage = MockAndroidWidgetCacheStorage();
      useCase = LogoutUseCase(
        authService: mockAuthService,
        androidWidgetCacheStorage: mockAndroidWidgetCacheStorage,
      );
    });

    test('ログアウトが正常に実行される', () async {
      when(mockAndroidWidgetCacheStorage.clear()).thenAnswer((_) async {});
      when(mockAndroidWidgetCacheStorage.updateWidget()).thenAnswer((_) async {});
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      await expectLater(useCase.execute(), completes);

      verify(mockAuthService.signOut()).called(1);
    });

    test('ログアウト時にウィジェットキャッシュを削除して即時更新する', () async {
      when(mockAndroidWidgetCacheStorage.clear()).thenAnswer((_) async {});
      when(mockAndroidWidgetCacheStorage.updateWidget()).thenAnswer((_) async {});
      when(mockAuthService.signOut()).thenAnswer((_) async {});

      await useCase.execute();

      verifyInOrder([
        mockAndroidWidgetCacheStorage.clear(),
        mockAndroidWidgetCacheStorage.updateWidget(),
        mockAuthService.signOut(),
      ]);
    });

    test('ログアウトでエラーが発生した場合は例外を再スローする', () async {
      when(mockAndroidWidgetCacheStorage.clear()).thenAnswer((_) async {});
      when(mockAndroidWidgetCacheStorage.updateWidget()).thenAnswer((_) async {});
      when(mockAuthService.signOut()).thenThrow(TestException('ログアウトエラー'));

      await expectLater(useCase.execute(), throwsA(isA<TestException>()));

      verify(mockAuthService.signOut()).called(1);
    });
  });
}
