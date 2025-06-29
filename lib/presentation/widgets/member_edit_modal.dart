import 'package:flutter/material.dart';
import '../../domain/entities/member.dart';

class MemberEditModal extends StatefulWidget {
  final Member? member;
  final Function(Member) onSave;

  const MemberEditModal({super.key, this.member, required this.onSave});

  @override
  State<MemberEditModal> createState() => _MemberEditModalState();
}

class _MemberEditModalState extends State<MemberEditModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _kanjiLastNameController;
  late TextEditingController _kanjiFirstNameController;
  late TextEditingController _hiraganaLastNameController;
  late TextEditingController _hiraganaFirstNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  String? _gender;
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.member?.nickname ?? '',
    );
    _kanjiLastNameController = TextEditingController(
      text: widget.member?.kanjiLastName ?? '',
    );
    _kanjiFirstNameController = TextEditingController(
      text: widget.member?.kanjiFirstName ?? '',
    );
    _hiraganaLastNameController = TextEditingController(
      text: widget.member?.hiraganaLastName ?? '',
    );
    _hiraganaFirstNameController = TextEditingController(
      text: widget.member?.hiraganaFirstName ?? '',
    );
    _firstNameController = TextEditingController(
      text: widget.member?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.member?.lastName ?? '',
    );
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _phoneNumberController = TextEditingController(
      text: widget.member?.phoneNumber ?? '',
    );
    _gender = widget.member?.gender;
    _birthday = widget.member?.birthday;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _kanjiLastNameController.dispose();
    _kanjiFirstNameController.dispose();
    _hiraganaLastNameController.dispose();
    _hiraganaFirstNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'メンバー編集' : 'メンバー新規作成',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'ニックネーム',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ニックネームを入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kanjiLastNameController,
                        decoration: const InputDecoration(
                          labelText: '姓（漢字）',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kanjiFirstNameController,
                        decoration: const InputDecoration(
                          labelText: '名（漢字）',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hiraganaLastNameController,
                        decoration: const InputDecoration(
                          labelText: '姓（ひらがな）',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hiraganaFirstNameController,
                        decoration: const InputDecoration(
                          labelText: '名（ひらがな）',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: '性別',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('男性')),
                          DropdownMenuItem(value: 'female', child: Text('女性')),
                          DropdownMenuItem(value: 'other', child: Text('その他')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _birthday ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              _birthday = selectedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '生年月日',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _birthday != null
                                ? '${_birthday!.year}/${_birthday!.month}/${_birthday!.day}'
                                : '選択してください',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'メールアドレス',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneNumberController,
                        decoration: const InputDecoration(
                          labelText: '電話番号',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final member = Member(
                        id: widget.member?.id ?? '',
                        accountId: widget.member?.accountId,
                        administratorId: widget.member?.administratorId,
                        nickname: _nicknameController.text,
                        kanjiLastName: _kanjiLastNameController.text.isEmpty
                            ? null
                            : _kanjiLastNameController.text,
                        kanjiFirstName: _kanjiFirstNameController.text.isEmpty
                            ? null
                            : _kanjiFirstNameController.text,
                        hiraganaLastName:
                            _hiraganaLastNameController.text.isEmpty
                            ? null
                            : _hiraganaLastNameController.text,
                        hiraganaFirstName:
                            _hiraganaFirstNameController.text.isEmpty
                            ? null
                            : _hiraganaFirstNameController.text,
                        firstName: _firstNameController.text.isEmpty
                            ? null
                            : _firstNameController.text,
                        lastName: _lastNameController.text.isEmpty
                            ? null
                            : _lastNameController.text,
                        gender: _gender,
                        birthday: _birthday,
                        email: _emailController.text.isEmpty
                            ? null
                            : _emailController.text,
                        phoneNumber: _phoneNumberController.text.isEmpty
                            ? null
                            : _phoneNumberController.text,
                        type: widget.member?.type,
                        passportNumber: widget.member?.passportNumber,
                        passportExpiration: widget.member?.passportExpiration,
                        anaMileageNumber: widget.member?.anaMileageNumber,
                        jalMileageNumber: widget.member?.jalMileageNumber,
                      );

                      widget.onSave(member);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(isEditing ? '更新' : '作成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
