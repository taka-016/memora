import 'package:memora/infrastructure/factories/auth_service_factory.dart';

import '../infrastructure/services/firebase_auth_service_test.mocks.dart';

import 'dart:async';

import '../../helpers/firestore_transaction_store.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/models/app_availability.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/composition_root/providers/app_availability_providers.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/infrastructure/factories/transaction_factory.dart';
import 'package:memora/presentation/notifiers/app_availability/app_availability_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/test_exception.dart';
import '../presentation/notifiers/app_availability/app_availability_notifier_test.mocks.dart';

void main() {
  late FirestoreTransactionStore store;
  late MockCheckAppAvailabilityUsecase check;
  late ProviderContainer container;
  final group = Group(id: 'g', ownerId: 'm', name: '変更後', version: 1);

  setUp(() async {
    store = FirestoreTransactionStore();
    store.rows['groups/g'] = {'name': '変更前', 'version': 1};
    check = MockCheckAppAvailabilityUsecase();
    container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.online),
        firebaseFirestoreProvider.overrideWithValue(store.firestore),
        checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
      ],
    );
  });
  tearDown(() => container.dispose());

  testWidgets('更新は進行中の確認を共有して待ち利用可能になったら書き込む', (tester) async {
    final pending = Completer<AppAvailability>();
    when(check.execute()).thenAnswer((_) => pending.future);
    container.read(appAvailabilityNotifierProvider);
    await tester.pump();
    final saving = container.read(groupRepositoryProvider).updateGroup(group);
    var transactionStarted = false;
    final transaction = container.read(writeTransactionProvider).run<void>((
      _,
    ) async {
      transactionStarted = true;
    });
    await tester.pump();
    expect(store.rows['groups/g']!['name'], '変更前');
    expect(transactionStarted, isFalse);
    pending.complete(AppAvailability.available);
    await tester.pump();
    await saving;
    await transaction;
    expect(store.rows['groups/g']!['name'], '変更後');
    expect(transactionStarted, isTrue);
    await container.read(writeTransactionProvider).run<void>((_) async {});
    verify(check.execute()).called(1);
  });

  for (final availability in [
    AppAvailability.maintenance,
    AppAvailability.updateRequired,
  ]) {
    testWidgets('$availabilityではRepositoryとトランザクションの更新を実行しない', (tester) async {
      when(check.execute()).thenAnswer((_) async => availability);
      container.read(appAvailabilityNotifierProvider);
      await tester.pump();
      await expectLater(
        container.read(groupRepositoryProvider).updateGroup(group),
        throwsA(isA<ApplicationValidationException>()),
      );
      var entered = false;
      await expectLater(
        container.read(writeTransactionProvider).run<void>((_) async {
          entered = true;
        }),
        throwsA(isA<ApplicationValidationException>()),
      );
      expect(entered, isFalse);
      expect(store.rows['groups/g']!['name'], '変更前');
    });
  }

  testWidgets('確認失敗では更新せず再確認成功後に同じ入力で保存できる', (tester) async {
    when(check.execute()).thenThrow(TestException('通信失敗'));
    final saving = container.read(groupRepositoryProvider).updateGroup(group);
    final failure = expectLater(
      saving,
      throwsA(isA<ApplicationValidationException>()),
    );
    await tester.pump();
    for (var attempt = 1; attempt < 5; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await failure;
    expect(store.rows['groups/g']!['name'], '変更前');
    when(check.execute()).thenAnswer((_) async => AppAvailability.available);
    final retry = container
        .read(appAvailabilityNotifierProvider.notifier)
        .refresh();
    await tester.pump();
    await retry;
    await container.read(groupRepositoryProvider).updateGroup(group);
    expect(store.rows['groups/g']!['name'], '変更後');
  });
  testWidgets('アカウントの変更も確認を待ち利用不可ならSDKへ渡さない', (tester) async {
    final auth = MockFirebaseAuth();
    final user = MockUser();
    when(auth.currentUser).thenReturn(user);
    final pending = Completer<AppAvailability>();
    when(check.execute()).thenAnswer((_) => pending.future);
    final accountContainer = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(auth),
        checkAppAvailabilityUsecaseProvider.overrideWithValue(check),
      ],
    );
    addTearDown(accountContainer.dispose);
    final service = accountContainer.read(authServiceProvider);
    final updating = service.updatePassword(newPassword: 'new-password');
    final failed = expectLater(
      updating,
      throwsA(isA<ApplicationValidationException>()),
    );
    await tester.pump();
    verifyNever(user.updatePassword(any));
    pending.complete(AppAvailability.maintenance);
    await tester.pump();
    await failed;
    await expectLater(
      service.deleteUser(),
      throwsA(isA<ApplicationValidationException>()),
    );
    await expectLater(
      service.updateEmail(newEmail: 'next@example.com'),
      throwsA(isA<ApplicationValidationException>()),
    );
    await expectLater(
      service.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'password',
      ),
      throwsA(isA<ApplicationValidationException>()),
    );
    verifyNever(user.delete());
    verifyNever(user.verifyBeforeUpdateEmail(any));
    verifyNever(
      auth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ),
    );
  });
}
