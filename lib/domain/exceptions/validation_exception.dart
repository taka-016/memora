/// ドメインエンティティのバリデーションエラーを表す例外
class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);

  @override
  String toString() => message;
}
