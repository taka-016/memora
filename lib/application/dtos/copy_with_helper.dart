/// copyWithメソッドで使用するプレースホルダー
/// nullable型のフィールドに対して、nullを明示的に設定するか、現在の値を保持するかを区別するために使用する
const copyWithPlaceholder = Object();

/// copyWithメソッドで使用する値解決のヘルパー関数
///
/// [value] が [copyWithPlaceholder] と同一の場合、[currentValue] を返す。
/// それ以外の場合、[value] の型を検証し、型 [T] にキャストして返す。
/// 型が一致しない場合は [ArgumentError] をスローする。
///
/// [fieldName] はエラーメッセージで使用されるフィールド名。
T? resolveCopyWithValue<T>(Object? value, T? currentValue, String fieldName) {
  if (identical(value, copyWithPlaceholder)) {
    return currentValue;
  }

  if (value == null || value is T) {
    return value as T?;
  }

  throw ArgumentError.value(
    value,
    fieldName,
    '型が不正です。${T.toString()}? 型を指定してください。',
  );
}
