import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseErrorUtil {
  static String getFirebaseErrorMessage(
    firebase_auth.FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています。ログインするか別のメールを利用してください。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'operation-not-allowed':
        return 'このサインイン方法は無効です。コンソールで有効化が必要です。';
      case 'weak-password':
        return 'パスワードが弱すぎます。より強力なパスワードを設定してください。';
      case 'user-disabled':
        return 'このアカウントは無効化されています。';
      case 'user-not-found':
        return 'ユーザーが見つかりません。メールアドレスを確認してください。';
      case 'wrong-password':
        return 'パスワードが間違っています。';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらくしてから再試行してください。';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました。通信環境を確認してください。';
      case 'requires-recent-login':
        return 'この操作には再ログインが必要です。いったんログアウトして再度ログインしてください。';
      case 'invalid-credential':
        return '認証情報が無効または期限切れです。やり直してください。';
      case 'account-exists-with-different-credential':
        return 'このメールは別のログイン方法で登録済みです。連携サインインを試してください。';
      case 'credential-already-in-use':
        return 'その認証情報は既に他のアカウントで使用されています。';
      case 'provider-already-linked':
        return 'このプロバイダは既にリンク済みです。';
      case 'no-such-provider':
        return 'リンクされていないプロバイダです。';
      case 'invalid-verification-code':
        return '確認コードが正しくありません。';
      case 'invalid-verification-id':
        return '確認IDが正しくありません。';
      case 'session-expired':
        return '確認コードの有効期限が切れています。再送信してください。';
      case 'missing-email':
        return 'メールアドレスを入力してください。';
      default:
        return error.message ?? 'エラーが発生しました。時間をおいて再試行してください。';
    }
  }
}
