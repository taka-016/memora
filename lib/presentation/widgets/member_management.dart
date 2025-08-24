import 'package:flutter/material.dart';
import '../../application/usecases/get_managed_members_usecase.dart';
import '../../application/usecases/create_member_usecase.dart';
import '../../application/usecases/update_member_usecase.dart';
import '../../application/usecases/delete_member_usecase.dart';
import '../../application/usecases/get_member_by_id_usecase.dart';
import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/repositories/trip_participant_repository.dart';
import '../../domain/repositories/group_member_repository.dart';
import '../../domain/repositories/member_event_repository.dart';
import '../../infrastructure/repositories/firestore_member_repository.dart';
import '../../infrastructure/repositories/firestore_trip_participant_repository.dart';
import '../../infrastructure/repositories/firestore_group_member_repository.dart';
import '../../infrastructure/repositories/firestore_member_event_repository.dart';
import 'member_edit_modal.dart';

class MemberManagement extends StatefulWidget {
  final Member member;
  final MemberRepository? memberRepository;
  final TripParticipantRepository? tripParticipantRepository;
  final GroupMemberRepository? groupMemberRepository;
  final MemberEventRepository? memberEventRepository;

  const MemberManagement({
    super.key,
    required this.member,
    this.memberRepository,
    this.tripParticipantRepository,
    this.groupMemberRepository,
    this.memberEventRepository,
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
    final tripParticipantRepository =
        widget.tripParticipantRepository ??
        FirestoreTripParticipantRepository();
    final groupMemberRepository =
        widget.groupMemberRepository ?? FirestoreGroupMemberRepository();
    final memberEventRepository =
        widget.memberEventRepository ?? FirestoreMemberEventRepository();

    _getManagedMembersUsecase = GetManagedMembersUsecase(memberRepository);
    _createMemberUsecase = CreateMemberUsecase(memberRepository);
    _updateMemberUsecase = UpdateMemberUsecase(memberRepository);
    _deleteMemberUsecase = DeleteMemberUsecase(
      memberRepository,
      tripParticipantRepository,
      groupMemberRepository,
      memberEventRepository,
    );
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
          } catch (e) {
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
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('更新に失敗しました: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(Member member) async {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteMember(member);
    }
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
    } catch (e) {
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
    final isCurrentUser = index == 0; // 1行目はログインユーザー

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
      // ログインユーザーでなく、かつaccountIdを持たない場合のみ削除ボタンを表示
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _showDeleteConfirmDialog(member),
      );
    }
    return null;
  }
}
