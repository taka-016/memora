import 'package:flutter/material.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/member.dart';

class GroupTimeline extends StatefulWidget {
  final Member? currentMember;
  final GetGroupsWithMembersUsecase? getGroupsWithMembersUsecase;

  const GroupTimeline({
    super.key,
    this.currentMember,
    this.getGroupsWithMembersUsecase,
  });

  @override
  State<GroupTimeline> createState() => _GroupTimelineState();
}

class _GroupTimelineState extends State<GroupTimeline> {
  bool _showTimeline = false;
  List<GroupWithMembers> _groups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (widget.currentMember != null &&
        widget.getGroupsWithMembersUsecase != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final groups = await widget.getGroupsWithMembersUsecase!.execute(
          widget.currentMember!,
        );
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _groups = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('group_timeline'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showTimeline) ...[
              const Text('テストグループ年表'),
            ] else ...[
              if (widget.currentMember != null &&
                  widget.getGroupsWithMembersUsecase != null) ...[
                if (_isLoading) ...[
                  const CircularProgressIndicator(),
                ] else if (_groups.isEmpty) ...[
                  const Text('グループが見つかりません'),
                ] else ...[
                  ..._groups.map(
                    (group) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _showTimeline = true;
                        });
                      },
                      child: Text(group.group.name),
                    ),
                  ),
                ],
              ] else ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showTimeline = true;
                    });
                  },
                  child: const Text('テストグループ'),
                ),
                const SizedBox(height: 16),
                const Text('グループが見つかりません'),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
