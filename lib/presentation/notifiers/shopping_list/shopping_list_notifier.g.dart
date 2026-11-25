// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
    r'583a4c5c3e436a9496fa1d556cb441a4acad3390';

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
