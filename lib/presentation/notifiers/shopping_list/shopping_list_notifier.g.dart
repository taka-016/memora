// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pendingShoppingList)
final pendingShoppingListProvider = PendingShoppingListFamily._();

final class PendingShoppingListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingListItem>>,
          List<ShoppingListItem>,
          Stream<List<ShoppingListItem>>
        >
    with
        $FutureModifier<List<ShoppingListItem>>,
        $StreamProvider<List<ShoppingListItem>> {
  PendingShoppingListProvider._({
    required PendingShoppingListFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'pendingShoppingListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingShoppingListHash();

  @override
  String toString() {
    return r'pendingShoppingListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ShoppingListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ShoppingListItem>> create(Ref ref) {
    final argument = this.argument as String;
    return pendingShoppingList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingShoppingListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingShoppingListHash() =>
    r'287914706fb4f3392fdb82680d5542156cb4c498';

final class PendingShoppingListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ShoppingListItem>>, String> {
  PendingShoppingListFamily._()
    : super(
        retry: _noRetry,
        name: r'pendingShoppingListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PendingShoppingListProvider call(String groupId) =>
      PendingShoppingListProvider._(argument: groupId, from: this);

  @override
  String toString() => r'pendingShoppingListProvider';
}

@ProviderFor(ShoppingListNotifier)
final shoppingListNotifierProvider = ShoppingListNotifierFamily._();

final class ShoppingListNotifierProvider
    extends $NotifierProvider<ShoppingListNotifier, ShoppingListState> {
  ShoppingListNotifierProvider._({
    required ShoppingListNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shoppingListNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingListNotifierHash();

  @override
  String toString() {
    return r'shoppingListNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShoppingListNotifier create() => ShoppingListNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShoppingListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShoppingListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShoppingListNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingListNotifierHash() =>
    r'5b5fcc92955e3544ab9c7b6c5b0e637baaa2abe9';

final class ShoppingListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ShoppingListNotifier,
          ShoppingListState,
          ShoppingListState,
          ShoppingListState,
          String
        > {
  ShoppingListNotifierFamily._()
    : super(
        retry: null,
        name: r'shoppingListNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShoppingListNotifierProvider call(String groupId) =>
      ShoppingListNotifierProvider._(argument: groupId, from: this);

  @override
  String toString() => r'shoppingListNotifierProvider';
}

abstract class _$ShoppingListNotifier extends $Notifier<ShoppingListState> {
  late final _$args = ref.$arg as String;
  String get groupId => _$args;

  ShoppingListState build(String groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShoppingListState, ShoppingListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShoppingListState, ShoppingListState>,
              ShoppingListState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ShoppingPurchasesNotifier)
final shoppingPurchasesNotifierProvider = ShoppingPurchasesNotifierFamily._();

final class ShoppingPurchasesNotifierProvider
    extends
        $AsyncNotifierProvider<
          ShoppingPurchasesNotifier,
          ShoppingPurchasesState
        > {
  ShoppingPurchasesNotifierProvider._({
    required ShoppingPurchasesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'shoppingPurchasesNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shoppingPurchasesNotifierHash();

  @override
  String toString() {
    return r'shoppingPurchasesNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ShoppingPurchasesNotifier create() => ShoppingPurchasesNotifier();

  @override
  bool operator ==(Object other) {
    return other is ShoppingPurchasesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shoppingPurchasesNotifierHash() =>
    r'aa4e08959870055a674274b02b29ffeddcbdf588';

final class ShoppingPurchasesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ShoppingPurchasesNotifier,
          AsyncValue<ShoppingPurchasesState>,
          ShoppingPurchasesState,
          FutureOr<ShoppingPurchasesState>,
          String
        > {
  ShoppingPurchasesNotifierFamily._()
    : super(
        retry: _noRetry,
        name: r'shoppingPurchasesNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShoppingPurchasesNotifierProvider call(String groupId) =>
      ShoppingPurchasesNotifierProvider._(argument: groupId, from: this);

  @override
  String toString() => r'shoppingPurchasesNotifierProvider';
}

abstract class _$ShoppingPurchasesNotifier
    extends $AsyncNotifier<ShoppingPurchasesState> {
  late final _$args = ref.$arg as String;
  String get groupId => _$args;

  FutureOr<ShoppingPurchasesState> build(String groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ShoppingPurchasesState>, ShoppingPurchasesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ShoppingPurchasesState>,
                ShoppingPurchasesState
              >,
              AsyncValue<ShoppingPurchasesState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
