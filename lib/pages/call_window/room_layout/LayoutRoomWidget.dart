import 'package:anoxia/pages/call_window/component/ParticipantTile.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

// 布局模式枚举
enum LayoutMode { grid, single, focus }

class LayoutRoomWidget extends StatefulWidget {
  final List<Participant> participants;
  const LayoutRoomWidget({super.key, required this.participants});

  @override
  State<LayoutRoomWidget> createState() => _LayoutRoomWidgetState();
}

class _LayoutRoomWidgetState extends State<LayoutRoomWidget> {
  LayoutMode _layoutMode = LayoutMode.grid;
  Participant? _focusedParticipant;
  @override
  Widget build(BuildContext context) {
    final count = widget.participants.length;
    final participants = widget.participants;

    // 自动选择布局
    _autoSelectLayoutMode(count);

    return Stack(
      children: [
        // 主布局内容
        _buildLayoutContent(count, participants),

        // 右上角 - 布局切换按钮
        Positioned(
          top: 12,
          right: 12,
          child: _buildLayoutSwitcher(),
        ),

        // 焦点参与者标签（仅在焦点模式下显示）
        if (_layoutMode == LayoutMode.focus && _focusedParticipant != null)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '焦点: ${_focusedParticipant?.name ?? '无名参与者'}',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  /// 自动选择布局模式
  void _autoSelectLayoutMode(int participantCount) {
    LayoutMode newMode;
    if (participantCount <= 1) {
      newMode = LayoutMode.single;
    } else if (participantCount == 2) {
      newMode = LayoutMode.focus;
    } else {
      newMode = LayoutMode.grid;
    }

    if (newMode != _layoutMode) {
      setState(() {
        _layoutMode = newMode;
        if (newMode == LayoutMode.single && widget.participants.isNotEmpty) {
          _focusedParticipant = widget.participants.first;
        } else if (newMode == LayoutMode.focus && widget.participants.isNotEmpty) {
          _focusedParticipant ??= widget.participants.first;
        }
      });
    }
  }

  /// 构建布局内容
  Widget _buildLayoutContent(int count, List<Participant> participants) {
    switch (_layoutMode) {
      // 单屏模式
      case LayoutMode.single:
        return GestureDetector(
          onTap: () {
            // 点击切换到下一个参与者
            if (participants.isNotEmpty) {
              final currentIndex = participants.indexOf(_focusedParticipant ?? participants.first);
              final nextIndex = (currentIndex + 1) % participants.length;
              setState(() => _focusedParticipant = participants[nextIndex]);
            }
          },
          child: ParticipantTile(
            participant: _focusedParticipant ?? participants.first,
          ),
        );

      // 焦点模式 (1对1显示对方)
      case LayoutMode.focus:
        return GestureDetector(
          onTap: () {
            if (participants.length > 1) {
              setState(() {
                _focusedParticipant = participants
                    .where((p) => p.sid != _focusedParticipant?.sid)
                    .firstOrNull;
              });
            }
          },
          child: ParticipantTile(
            participant: _focusedParticipant ?? (participants.isNotEmpty ? participants.first : participants.first),
          ),
        );

      // 网格模式 (默认)
      case LayoutMode.grid:
        if (count == 1) {
          return ParticipantTile(participant: participants[0]);
        }
        if (count == 2) {
          return Row(
            children: [
              Expanded(child: ParticipantTile(participant: participants[0])),
              Expanded(child: ParticipantTile(participant: participants[1])),
            ],
          );
        }
        // 3-4人：田字格 (2x2)
        if (count <= 4) {
          final row1 = participants.take(2).toList();
          final row2 = participants.skip(2).toList();

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: ParticipantTile(participant: row1[0])),
                    const SizedBox(width: 8),
                    Expanded(
                      child: row1.length > 1
                          ? ParticipantTile(participant: row1[1])
                          : const Spacer(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: ParticipantTile(participant: row2[0])),
                    const SizedBox(width: 8),
                    Expanded(
                      child: row2.length > 1
                          ? ParticipantTile(participant: row2[1])
                          : const Spacer(),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return GridView.builder(
          itemCount: count,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) =>
              ParticipantTile(participant: participants[index]),
        );
    }
  }

  /// 构建布局切换按钮
  Widget _buildLayoutSwitcher() {
    return PopupMenuButton<LayoutMode>(
      initialValue: _layoutMode,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (mode) {
        setState(() {
          _layoutMode = mode;
          if (widget.participants.isNotEmpty) {
            _focusedParticipant = widget.participants.first;
          }
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: LayoutMode.single,
          child: Row(
            children: [
              Icon(Icons.fullscreen, size: 18),
              SizedBox(width: 12),
              Text('单屏'),
            ],
          ),
        ),
        PopupMenuItem(
          value: LayoutMode.focus,
          child: Row(
            children: [
              Icon(Icons.zoom_in, size: 18),
              SizedBox(width: 12),
              Text('焦点'),
            ],
          ),
        ),
        PopupMenuItem(
          value: LayoutMode.grid,
          child: Row(
            children: [
              Icon(Icons.grid_3x3, size: 18),
              SizedBox(width: 12),
              Text('网格'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getLayoutIcon(),
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  IconData _getLayoutIcon() {
    switch (_layoutMode) {
      case LayoutMode.single:
        return Icons.fullscreen;
      case LayoutMode.focus:
        return Icons.zoom_in;
      case LayoutMode.grid:
        return Icons.grid_3x3;
    }
  }
}
