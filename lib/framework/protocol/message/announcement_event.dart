import '../i_packet.dart';

enum AnnouncementAction { published, updated, offline }

/// 公告变更提示；公告内容必须通过 REST 重新获取。
class AnnouncementEvent implements IPacket {
  const AnnouncementEvent({
    required this.id,
    required this.revision,
    required this.action,
  });

  final int id;
  final int revision;
  final AnnouncementAction action;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'action': action.name,
  };
}
