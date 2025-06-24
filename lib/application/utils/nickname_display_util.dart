import '../../domain/entities/member.dart';

class NicknameDisplayUtil {
  static String getDisplayName(Member member) {
    // ニックネームが設定されている場合（空文字や空白文字でない場合）
    if (member.nickname != null && member.nickname!.trim().isNotEmpty) {
      return member.nickname!;
    }

    // 漢字姓名のいずれかが設定されている場合
    final hasLastName =
        member.kanjiLastName != null && member.kanjiLastName!.trim().isNotEmpty;
    final hasFirstName =
        member.kanjiFirstName != null &&
        member.kanjiFirstName!.trim().isNotEmpty;

    if (hasLastName || hasFirstName) {
      // nullは空文字に変換して結合
      final lastName = member.kanjiLastName ?? '';
      final firstName = member.kanjiFirstName ?? '';
      return '$lastName $firstName'.trim();
    }

    // どちらも設定されていない場合
    return '名前未設定';
  }
}
