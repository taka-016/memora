import 'package:flutter/material.dart';
import 'package:memora/domain/repositories/group_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_group_repository.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/application/usecases/member/create_or_update_member_invitation_usecase.dart';
import 'package:memora/infrastructure/repositories/firestore_member_invitation_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/usecases/member/create_member_usecase.dart';
import 'package:memora/application/usecases/member/update_member_usecase.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';
import 'package:memora/application/usecases/member/get_member_by_id_usecase.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/domain/repositories/member_event_repository.dart';
import 'package:memora/domain/repositories/member_invitation_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_member_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_member_event_repository.dart';
import 'member_edit_modal.dart';
import 'package:memora/core/app_logger.dart';

class MemberManagement extends StatefulWidget {
  final Member member;
  final MemberRepository? memberRepository;
  final GroupRepository? groupRepository;
  final MemberEventRepository? memberEventRepository;
  final MemberInvitationRepository? memberInvitationRepository;

  const MemberManagement({
    super.key,
    required this.member,
    this.memberRepository,
    this.groupRepository,
    this.memberEventRepository,
    this.memberInvitationRepository,
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
  late final CreateOrUpdateMemberInvitationUsecase
  _createOrUpdateMemberInvitationUsecase;

  List<Member> _managedMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final memberRepository =
        widget.memberRepository ?? FirestoreMemberRepository();
    final groupRepository =
        widget.groupRepository ?? FirestoreGroupRepository();
    final memberEventRepository =
        widget.memberEventRepository ?? FirestoreMemberEventRepository();
    final memberInvitationRepository =
        widget.memberInvitationRepository ??
        FirestoreMemberInvitationRepository(FirebaseFirestore.instance);

    _getManagedMembersUsecase = GetManagedMembersUsecase(memberRepository);
    _createMemberUsecase = CreateMemberUsecase(memberRepository);
    _updateMemberUsecase = UpdateMemberUsecase(memberRepository);
    _deleteMemberUsecase = DeleteMemberUsecase(
      memberRepository,
      groupRepository,
      memberEventRepository,
    );
    _getMemberByIdUseCase = GetMemberByIdUseCase(memberRepository);
    _createOrUpdateMemberInvitationUsecase =
        CreateOrUpdateMemberInvitationUsecase(memberInvitationRepository);

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
      final currentMember = await _getMemberByIdUseCase.execute(
        widget.member.id,
      );
      if (currentMember == null) {
        throw Exception('ログインユーザーメンバーの最新情報の取得に失敗しました');
      }
      _managedMembers = [currentMember, ...managedMembers];
    } catch (e, stack) {
      logger.e(
        'MemberManagement._loadData: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
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

  Future<void> _showAddMemberDialog() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => MemberEditModal(
        onSave: (member) async {
          try {
            await _createMemberUsecase.execute(member, widget.member.id);
            if (mounted) {
              await _loadData();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('メンバーを作成しました')),
              );
            }
          } catch (e, stack) {
            logger.e(
              'MemberManagement._showAddMemberDialog: ${e.toString()}',
              error: e,
              stackTrace: stack,
            );
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('作成に失敗しました: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showEditMemberDialog(Member member) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => MemberEditModal(
        member: member,
        onSave: (updatedMember) async {
          try {
            await _updateMemberUsecase.execute(updatedMember);
            if (mounted) {
              await _loadData();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('メンバーを更新しました')),
              );
            }
          } catch (e, stack) {
            logger.e(
              'MemberManagement._showEditMemberDialog: ${e.toString()}',
              error: e,
              stackTrace: stack,
            );
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('更新に失敗しました: $e')),
              );
            }
          }
        },
        onInvite: member.id != widget.member.id
            ? (member) async {
                await _handleMemberInvite(member);
              }
            : null,
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(Member member) async {
    await DeleteConfirmDialog.show(
      context,
      title: 'メンバー削除',
      content: '${member.displayName}を削除しますか？',
      onConfirm: () => _deleteMember(member),
    );
  }

  Future<void> _deleteMember(Member member) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _deleteMemberUsecase.execute(member.id);
      if (mounted) {
        await _loadData();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('メンバーを削除しました')),
        );
      }
    } catch (e, stack) {
      logger.e(
        'MemberManagement._deleteMember: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
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
              children: [_buildHeader(), const Divider(), _buildMemberList()],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Text(
            'メンバー管理',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _showAddMemberDialog,
            icon: const Icon(Icons.add),
            label: const Text('メンバー追加'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          itemCount: _managedMembers.length,
          itemBuilder: (context, index) {
            final member = _managedMembers[index];
            return _buildMemberItem(member, index);
          },
        ),
      ),
    );
  }

  Widget _buildMemberItem(Member member, int index) {
    final isCurrentUser = index == 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text(member.displayName.substring(0, 1))),
        title: Text(member.displayName),
        subtitle: _buildMemberSubtitle(member),
        onTap: () => _showEditMemberDialog(member),
        trailing: _buildMemberTrailing(member, isCurrentUser),
      ),
    );
  }

  Widget? _buildMemberSubtitle(Member member) {
    if (member.email != null || member.phoneNumber != null) {
      return Text(member.email ?? member.phoneNumber ?? '');
    }
    return null;
  }

  Widget? _buildMemberTrailing(Member member, bool isCurrentUser) {
    if (!isCurrentUser && member.accountId == null) {
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _showDeleteConfirmDialog(member),
      );
    }
    return null;
  }

  Future<void> _handleMemberInvite(Member member) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final invitationCode = await _createOrUpdateMemberInvitationUsecase
          .execute(inviteeId: member.id, inviterId: widget.member.id);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('招待コード'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${member.displayName}さんの招待コードが生成されました。'),
                const SizedBox(height: 16),
                SelectableText(
                  invitationCode,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    await Share.share(
                      'あなたのMemoraへの招待コード\n\n$invitationCode\n\nこのコードをアプリで入力してください。',
                      subject: 'Memoraへの招待',
                    );
                  } catch (e, stack) {
                    logger.e(
                      'MemberManagement._handleMemberInvite.shareDialog: ${e.toString()}',
                      error: e,
                      stackTrace: stack,
                    );
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('共有に失敗しました')),
                    );
                  }
                },
                child: const Text('共有'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    } catch (e, stack) {
      logger.e(
        'MemberManagement._handleMemberInvite: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('招待コードの生成に失敗しました: $e')),
        );
      }
    }
  }
}
