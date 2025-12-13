import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';

class MemberEditModal extends HookWidget {
  final MemberDto? member;
  final Function(Member) onSave;
  final Function(MemberDto)? onInvite;

  const MemberEditModal({
    super.key,
    this.member,
    required this.onSave,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final displayNameController = useTextEditingController(
      text: member?.displayName ?? '',
    );
    final kanjiLastNameController = useTextEditingController(
      text: member?.kanjiLastName ?? '',
    );
    final kanjiFirstNameController = useTextEditingController(
      text: member?.kanjiFirstName ?? '',
    );
    final hiraganaLastNameController = useTextEditingController(
      text: member?.hiraganaLastName ?? '',
    );
    final hiraganaFirstNameController = useTextEditingController(
      text: member?.hiraganaFirstName ?? '',
    );
    final firstNameController = useTextEditingController(
      text: member?.firstName ?? '',
    );
    final lastNameController = useTextEditingController(
      text: member?.lastName ?? '',
    );
    final emailController = useTextEditingController(text: member?.email ?? '');
    final phoneNumberController = useTextEditingController(
      text: member?.phoneNumber ?? '',
    );
    final gender = useState<String?>(member?.gender);
    final birthday = useState<DateTime?>(member?.birthday);

    final isEditing = member != null;

    Widget buildHeader() {
      return Text(
        isEditing ? 'メンバー編集' : 'メンバー新規作成',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      );
    }

    Widget buildDisplayNameField() {
      return TextFormField(
        controller: displayNameController,
        decoration: const InputDecoration(
          labelText: '表示名',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '表示名を入力してください';
          }
          return null;
        },
      );
    }

    Widget buildKanjiNameFields() {
      return Column(
        children: [
          TextFormField(
            controller: kanjiLastNameController,
            decoration: const InputDecoration(
              labelText: '姓（漢字）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: kanjiFirstNameController,
            decoration: const InputDecoration(
              labelText: '名（漢字）',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );
    }

    Widget buildHiraganaNameFields() {
      return Column(
        children: [
          TextFormField(
            controller: hiraganaLastNameController,
            decoration: const InputDecoration(
              labelText: '姓（ひらがな）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: hiraganaFirstNameController,
            decoration: const InputDecoration(
              labelText: '名（ひらがな）',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );
    }

    Widget buildEnglishNameFields() {
      return Column(
        children: [
          TextFormField(
            controller: firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      );
    }

    Widget buildGenderField() {
      return DropdownButtonFormField<String>(
        initialValue: gender.value,
        decoration: const InputDecoration(
          labelText: '性別',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: '男性', child: Text('男性')),
          DropdownMenuItem(value: '女性', child: Text('女性')),
          DropdownMenuItem(value: 'その他', child: Text('その他')),
        ],
        onChanged: (value) {
          gender.value = value;
        },
      );
    }

    Widget buildBirthdayField() {
      return InkWell(
        onTap: () async {
          final selectedDate = await DatePickerHelper.showCustomDatePicker(
            context,
            initialDate: birthday.value ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (selectedDate != null) {
            birthday.value = selectedDate;
          }
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: '生年月日',
            border: OutlineInputBorder(),
          ),
          child: Text(
            birthday.value != null
                ? '${birthday.value!.year}/${birthday.value!.month}/${birthday.value!.day}'
                : '選択してください',
          ),
        ),
      );
    }

    Widget buildContactFields() {
      return Column(
        children: [
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'メールアドレス',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneNumberController,
            decoration: const InputDecoration(
              labelText: '電話番号',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      );
    }

    Widget buildForm() {
      return Expanded(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildDisplayNameField(),
                const SizedBox(height: 16),
                buildKanjiNameFields(),
                const SizedBox(height: 16),
                buildHiraganaNameFields(),
                const SizedBox(height: 16),
                buildEnglishNameFields(),
                const SizedBox(height: 16),
                buildGenderField(),
                const SizedBox(height: 16),
                buildBirthdayField(),
                const SizedBox(height: 16),
                buildContactFields(),
              ],
            ),
          ),
        ),
      );
    }

    void handleInvite() {
      if (member != null && onInvite != null) {
        onInvite!(member!);
      }
    }

    void handleSave() {
      if (formKey.currentState!.validate()) {
        final savedMember = Member(
          id: member?.id ?? '',
          accountId: member?.accountId,
          ownerId: member?.ownerId,
          displayName: displayNameController.text,
          kanjiLastName: kanjiLastNameController.text.isEmpty
              ? null
              : kanjiLastNameController.text,
          kanjiFirstName: kanjiFirstNameController.text.isEmpty
              ? null
              : kanjiFirstNameController.text,
          hiraganaLastName: hiraganaLastNameController.text.isEmpty
              ? null
              : hiraganaLastNameController.text,
          hiraganaFirstName: hiraganaFirstNameController.text.isEmpty
              ? null
              : hiraganaFirstNameController.text,
          firstName: firstNameController.text.isEmpty
              ? null
              : firstNameController.text,
          lastName: lastNameController.text.isEmpty
              ? null
              : lastNameController.text,
          gender: gender.value,
          birthday: birthday.value,
          email: emailController.text.isEmpty ? null : emailController.text,
          phoneNumber: phoneNumberController.text.isEmpty
              ? null
              : phoneNumberController.text,
          type: member?.type,
          passportNumber: member?.passportNumber,
          passportExpiration: member?.passportExpiration,
        );

        onSave(savedMember);
        Navigator.of(context).pop();
      }
    }

    Widget buildActionButtons() {
      return Column(
        children: [
          if (isEditing && onInvite != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: handleInvite,
                  icon: const Icon(Icons.person_add),
                  label: const Text('招待'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: handleSave,
                child: Text(isEditing ? '更新' : '作成'),
              ),
            ],
          ),
        ],
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Material(
        type: MaterialType.card,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              const SizedBox(height: 20),
              buildForm(),
              const SizedBox(height: 24),
              buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
