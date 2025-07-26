import 'package:flutter/material.dart';
import '../../application/usecases/get_managed_members_usecase.dart';
import '../../application/usecases/create_member_usecase.dart';
import '../../application/usecases/update_member_usecase.dart';
import '../../application/usecases/delete_member_usecase.dart';
import '../../application/usecases/get_member_by_id_usecase.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../../infrastructure/repositories/firestore_member_repository.dart';
import 'member_edit_modal.dart';

class MemberManagement extends StatefulWidget {
  final Member member;
  final MemberRepository? memberRepository;

  const MemberManagement({
    super.key,
    required this.member,
    this.memberRepository,
  });

  @override
  State<MemberManagement> createState() => _MemberManagementState();
}

class _MemberManagementState extends State<MemberManagement> {
  late final GetManagedMembersUsecase _getManagedMembersUsecase;
  late final CreateMemberUsecase _createMemberUsecase;
  late final UpdateMemberUsecase _updateMemberUsecase;
  late final DeleteMemberUsecase _deleteMemberUsecase;
  late final GetMemberByIdUseCase _getMemberByIdUseCase;

  List<Member> _managedMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 注入されたリポジトリまたはデフォルトのFirestoreリポジトリを使用
    final memberRepository =
        widget.memberRepository ?? FirestoreMemberRepository();

    _getManagedMembersUsecase = GetManagedMembersUsecase(memberRepository);
    _createMemberUsecase = CreateMemberUsecase(memberRepository);
    _updateMemberUsecase = UpdateMemberUsecase(memberRepository);
    _deleteMemberUsecase = DeleteMemberUsecase(memberRepository);
    _getMemberByIdUseCase = GetMemberByIdUseCase(memberRepository);

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final managedMembers = await _getManagedMembersUsecase.execute(
        widget.member,
      );
      // 1行目にログインユーザーのメンバーを表示するため、DBから最新情報を取得
      final currentMember = await _getMemberByIdUseCase.execute(
        widget.member.id,
      );
      if (currentMember == null) {
        throw Exception('ログインユーザーメンバーの最新情報の取得に失敗しました');
      }
      _managedMembers = [currentMember, ...managedMembers];
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
              await _createMemberUsecase.execute(
                editedMember,
                widget.member.id,
              );
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
        content: Text('${member.displayName}を削除しますか？'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('member_settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Text(
                        'メンバー管理',
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
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      itemCount: _managedMembers.length,
                      itemBuilder: (context, index) {
                        final member = _managedMembers[index];
                        final isCurrentUser = index == 0; // 1行目はログインユーザー

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(member.displayName.substring(0, 1)),
                            ),
                            title: Text(member.displayName),
                            subtitle:
                                member.email != null ||
                                    member.phoneNumber != null
                                ? Text(member.email ?? member.phoneNumber ?? '')
                                : null,
                            onTap: () => _showMemberEditModal(member: member),
                            trailing:
                                !isCurrentUser // ログインユーザーでない場合のみ削除ボタンを表示
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteMember(member),
                                  )
                                : null,
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
