import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../application/usecases/get_current_member_usecase.dart';
import '../../application/usecases/get_managed_members_usecase.dart';
import '../../application/usecases/create_member_usecase.dart';
import '../../application/usecases/update_member_usecase.dart';
import '../../application/usecases/delete_member_usecase.dart';
import '../../domain/entities/member.dart';
import '../../infrastructure/repositories/firestore_member_repository.dart';
import '../../infrastructure/services/firebase_auth_service.dart';
import 'member_edit_modal.dart';

class MemberSettings extends StatefulWidget {
  final GetCurrentMemberUseCase? getCurrentMemberUseCase;
  final GetManagedMembersUsecase? getManagedMembersUsecase;
  final CreateMemberUsecase? createMemberUsecase;
  final UpdateMemberUsecase? updateMemberUsecase;
  final DeleteMemberUsecase? deleteMemberUsecase;

  const MemberSettings({
    super.key,
    this.getCurrentMemberUseCase,
    this.getManagedMembersUsecase,
    this.createMemberUsecase,
    this.updateMemberUsecase,
    this.deleteMemberUsecase,
  });

  @override
  State<MemberSettings> createState() => _MemberSettingsState();
}

class _MemberSettingsState extends State<MemberSettings> {
  late final GetCurrentMemberUseCase _getCurrentMemberUseCase;
  late final GetManagedMembersUsecase _getManagedMembersUsecase;
  late final CreateMemberUsecase _createMemberUsecase;
  late final UpdateMemberUsecase _updateMemberUsecase;
  late final DeleteMemberUsecase _deleteMemberUsecase;

  Member? _currentMember;
  List<Member> _managedMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    if (widget.getCurrentMemberUseCase != null &&
        widget.getManagedMembersUsecase != null &&
        widget.createMemberUsecase != null &&
        widget.updateMemberUsecase != null &&
        widget.deleteMemberUsecase != null) {
      // テスト環境では注入されたユースケースを使用
      _getCurrentMemberUseCase = widget.getCurrentMemberUseCase!;
      _getManagedMembersUsecase = widget.getManagedMembersUsecase!;
      _createMemberUsecase = widget.createMemberUsecase!;
      _updateMemberUsecase = widget.updateMemberUsecase!;
      _deleteMemberUsecase = widget.deleteMemberUsecase!;
      _loadData();
    } else {
      // 本番環境ではFirebaseを直接使用
      _initializeUseCases();
    }
  }

  void _initializeUseCases() {
    // 本番環境では従来通りFirebaseを直接使用
    final memberRepository = FirestoreMemberRepository();
    final authService = FirebaseAuthService();

    _getCurrentMemberUseCase = GetCurrentMemberUseCase(
      memberRepository,
      authService,
    );
    _getManagedMembersUsecase = GetManagedMembersUsecase(memberRepository);
    _createMemberUsecase = CreateMemberUsecase(memberRepository);
    _updateMemberUsecase = UpdateMemberUsecase(memberRepository);
    _deleteMemberUsecase = DeleteMemberUsecase(memberRepository);

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentMember = await _getCurrentMemberUseCase.execute();
      if (_currentMember != null) {
        _managedMembers = await _getManagedMembersUsecase.execute(
          _currentMember!,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('データの読み込みに失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showMemberEditModal({Member? member}) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => MemberEditModal(
        member: member,
        onSave: (editedMember) async {
          try {
            if (member == null) {
              final newMember = Member(
                id: const Uuid().v4(),
                accountId: editedMember.accountId,
                administratorId: _currentMember!.id,
                nickname: editedMember.nickname,
                kanjiLastName: editedMember.kanjiLastName,
                kanjiFirstName: editedMember.kanjiFirstName,
                hiraganaLastName: editedMember.hiraganaLastName,
                hiraganaFirstName: editedMember.hiraganaFirstName,
                firstName: editedMember.firstName,
                lastName: editedMember.lastName,
                gender: editedMember.gender,
                birthday: editedMember.birthday,
                email: editedMember.email,
                phoneNumber: editedMember.phoneNumber,
                type: editedMember.type,
                passportNumber: editedMember.passportNumber,
                passportExpiration: editedMember.passportExpiration,
                anaMileageNumber: editedMember.anaMileageNumber,
                jalMileageNumber: editedMember.jalMileageNumber,
              );
              await _createMemberUsecase.execute(_currentMember!, newMember);
            } else {
              await _updateMemberUsecase.execute(editedMember);
            }
            if (mounted) {
              await _loadData();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(member == null ? 'メンバーを作成しました' : 'メンバーを更新しました'),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('操作に失敗しました: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteMember(Member member) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバー削除'),
        content: Text(
          '${member.nickname ?? member.kanjiLastName ?? member.firstName ?? 'このメンバー'}を削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _deleteMemberUsecase.execute(member.id);
        if (mounted) {
          await _loadData();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('メンバーを削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  String _getMemberDisplayName(Member member) {
    if (member.nickname != null && member.nickname!.isNotEmpty) {
      return member.nickname!;
    }
    if (member.kanjiLastName != null && member.kanjiFirstName != null) {
      return '${member.kanjiLastName} ${member.kanjiFirstName}';
    }
    if (member.firstName != null && member.lastName != null) {
      return '${member.firstName} ${member.lastName}';
    }
    return '名前未設定';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('member_settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentMember == null
          ? const Center(child: Text('ログインが必要です'))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 32),
                      const SizedBox(width: 16),
                      const Text(
                        'メンバー設定',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showMemberEditModal(),
                        icon: const Icon(Icons.add),
                        label: const Text('メンバー追加'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _managedMembers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '管理しているメンバーがいません',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'メンバー追加ボタンから新しいメンバーを追加してください',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: _managedMembers.length,
                            itemBuilder: (context, index) {
                              final member = _managedMembers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      _getMemberDisplayName(
                                        member,
                                      ).substring(0, 1),
                                    ),
                                  ),
                                  title: Text(_getMemberDisplayName(member)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (member.email != null)
                                        Text('メール: ${member.email}'),
                                      if (member.phoneNumber != null)
                                        Text('電話: ${member.phoneNumber}'),
                                      if (member.birthday != null)
                                        Text(
                                          '生年月日: ${member.birthday!.year}/${member.birthday!.month}/${member.birthday!.day}',
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showMemberEditModal(
                                          member: member,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteMember(member),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
