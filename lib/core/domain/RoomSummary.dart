import 'dart:convert';
/// msg : "操作成功"
/// code : 200
/// data : [{"roomId":"testroom2","roomName":"testGroup1","roomAvatar":"","roomDescription":"测试用群聊","roomStatus":0,"roomType":0,"joinTime":1756799546000,"lastActiveTime":null,"roleId":2,"roleName":"member","permissionsJson":"[\"SEND_MESSAGE\", \"READ_MESSAGE\"]","lastMessage":{"messageId":"368601b5617f4b5c9078ec15e38ceb71","roomId":"testroom2","senderId":1,"messageType":0,"messageStatus":0,"timestamp":1758770002766,"content":{"messageId":null,"text":"你好","type":0,"extra":{}},"system":null,"attachment":null,"readUserIds":null},"unreadCount":13},{"roomId":"testroom1","roomName":"testSingle1","roomAvatar":"","roomDescription":"测试用私聊","roomStatus":0,"roomType":0,"joinTime":1756799365000,"lastActiveTime":null,"roleId":1,"roleName":"member","permissionsJson":"[\"SEND_MESSAGE\", \"READ_MESSAGE\"]","lastMessage":{"messageId":"ef9580a9-928c-44d8-8cfa-9b82bc50218d","roomId":"testroom1","senderId":3,"messageType":0,"messageStatus":0,"timestamp":1757920701471,"content":{"messageId":null,"text":"测试消息 97 来自用户 3","type":0,"extra":{}},"system":null,"attachment":null,"readUserIds":null},"unreadCount":12}]

RoomSummary roomSummaryFromJson(String str) => RoomSummary.fromJson(json.decode(str));
String roomSummaryToJson(RoomSummary data) => json.encode(data.toJson());
class RoomSummary {
  RoomSummary({
      String? msg, 
      num? code, 
      List<Data>? data,}){
    _msg = msg;
    _code = code;
    _data = data;
}

  RoomSummary.fromJson(dynamic json) {
    _msg = json['msg'];
    _code = json['code'];
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Data.fromJson(v));
      });
    }
  }
  String? _msg;
  num? _code;
  List<Data>? _data;
RoomSummary copyWith({  String? msg,
  num? code,
  List<Data>? data,
}) => RoomSummary(  msg: msg ?? _msg,
  code: code ?? _code,
  data: data ?? _data,
);
  String? get msg => _msg;
  num? get code => _code;
  List<Data>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['msg'] = _msg;
    map['code'] = _code;
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// roomId : "testroom2"
/// roomName : "testGroup1"
/// roomAvatar : ""
/// roomDescription : "测试用群聊"
/// roomStatus : 0
/// roomType : 0
/// joinTime : 1756799546000
/// lastActiveTime : null
/// roleId : 2
/// roleName : "member"
/// permissionsJson : "[\"SEND_MESSAGE\", \"READ_MESSAGE\"]"
/// lastMessage : {"messageId":"368601b5617f4b5c9078ec15e38ceb71","roomId":"testroom2","senderId":1,"messageType":0,"messageStatus":0,"timestamp":1758770002766,"content":{"messageId":null,"text":"你好","type":0,"extra":{}},"system":null,"attachment":null,"readUserIds":null}
/// unreadCount : 13

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      String? roomId, 
      String? roomName, 
      String? roomAvatar, 
      String? roomDescription, 
      num? roomStatus, 
      num? roomType, 
      num? joinTime, 
      dynamic lastActiveTime, 
      num? roleId, 
      String? roleName, 
      String? permissionsJson, 
      LastMessage? lastMessage, 
      num? unreadCount,}){
    _roomId = roomId;
    _roomName = roomName;
    _roomAvatar = roomAvatar;
    _roomDescription = roomDescription;
    _roomStatus = roomStatus;
    _roomType = roomType;
    _joinTime = joinTime;
    _lastActiveTime = lastActiveTime;
    _roleId = roleId;
    _roleName = roleName;
    _permissionsJson = permissionsJson;
    _lastMessage = lastMessage;
    _unreadCount = unreadCount;
}

  Data.fromJson(dynamic json) {
    _roomId = json['roomId'];
    _roomName = json['roomName'];
    _roomAvatar = json['roomAvatar'];
    _roomDescription = json['roomDescription'];
    _roomStatus = json['roomStatus'];
    _roomType = json['roomType'];
    _joinTime = json['joinTime'];
    _lastActiveTime = json['lastActiveTime'];
    _roleId = json['roleId'];
    _roleName = json['roleName'];
    _permissionsJson = json['permissionsJson'];
    _lastMessage = json['lastMessage'] != null ? LastMessage.fromJson(json['lastMessage']) : null;
    _unreadCount = json['unreadCount'];
  }
  String? _roomId;
  String? _roomName;
  String? _roomAvatar;
  String? _roomDescription;
  num? _roomStatus;
  num? _roomType;
  num? _joinTime;
  dynamic _lastActiveTime;
  num? _roleId;
  String? _roleName;
  String? _permissionsJson;
  LastMessage? _lastMessage;
  num? _unreadCount;
Data copyWith({  String? roomId,
  String? roomName,
  String? roomAvatar,
  String? roomDescription,
  num? roomStatus,
  num? roomType,
  num? joinTime,
  dynamic lastActiveTime,
  num? roleId,
  String? roleName,
  String? permissionsJson,
  LastMessage? lastMessage,
  num? unreadCount,
}) => Data(  roomId: roomId ?? _roomId,
  roomName: roomName ?? _roomName,
  roomAvatar: roomAvatar ?? _roomAvatar,
  roomDescription: roomDescription ?? _roomDescription,
  roomStatus: roomStatus ?? _roomStatus,
  roomType: roomType ?? _roomType,
  joinTime: joinTime ?? _joinTime,
  lastActiveTime: lastActiveTime ?? _lastActiveTime,
  roleId: roleId ?? _roleId,
  roleName: roleName ?? _roleName,
  permissionsJson: permissionsJson ?? _permissionsJson,
  lastMessage: lastMessage ?? _lastMessage,
  unreadCount: unreadCount ?? _unreadCount,
);
  String? get roomId => _roomId;
  String? get roomName => _roomName;
  String? get roomAvatar => _roomAvatar;
  String? get roomDescription => _roomDescription;
  num? get roomStatus => _roomStatus;
  num? get roomType => _roomType;
  num? get joinTime => _joinTime;
  dynamic get lastActiveTime => _lastActiveTime;
  num? get roleId => _roleId;
  String? get roleName => _roleName;
  String? get permissionsJson => _permissionsJson;
  LastMessage? get lastMessage => _lastMessage;
  num? get unreadCount => _unreadCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['roomId'] = _roomId;
    map['roomName'] = _roomName;
    map['roomAvatar'] = _roomAvatar;
    map['roomDescription'] = _roomDescription;
    map['roomStatus'] = _roomStatus;
    map['roomType'] = _roomType;
    map['joinTime'] = _joinTime;
    map['lastActiveTime'] = _lastActiveTime;
    map['roleId'] = _roleId;
    map['roleName'] = _roleName;
    map['permissionsJson'] = _permissionsJson;
    if (_lastMessage != null) {
      map['lastMessage'] = _lastMessage?.toJson();
    }
    map['unreadCount'] = _unreadCount;
    return map;
  }

}

/// messageId : "368601b5617f4b5c9078ec15e38ceb71"
/// roomId : "testroom2"
/// senderId : 1
/// messageType : 0
/// messageStatus : 0
/// timestamp : 1758770002766
/// content : {"messageId":null,"text":"你好","type":0,"extra":{}}
/// system : null
/// attachment : null
/// readUserIds : null

LastMessage lastMessageFromJson(String str) => LastMessage.fromJson(json.decode(str));
String lastMessageToJson(LastMessage data) => json.encode(data.toJson());
class LastMessage {
  LastMessage({
      String? messageId, 
      String? roomId, 
      num? senderId, 
      num? messageType, 
      num? messageStatus, 
      num? timestamp, 
      Content? content, 
      dynamic system, 
      dynamic attachment, 
      dynamic readUserIds,}){
    _messageId = messageId;
    _roomId = roomId;
    _senderId = senderId;
    _messageType = messageType;
    _messageStatus = messageStatus;
    _timestamp = timestamp;
    _content = content;
    _system = system;
    _attachment = attachment;
    _readUserIds = readUserIds;
}

  LastMessage.fromJson(dynamic json) {
    _messageId = json['messageId'];
    _roomId = json['roomId'];
    _senderId = json['senderId'];
    _messageType = json['messageType'];
    _messageStatus = json['messageStatus'];
    _timestamp = json['timestamp'];
    _content = json['content'] != null ? Content.fromJson(json['content']) : null;
    _system = json['system'];
    _attachment = json['attachment'];
    _readUserIds = json['readUserIds'];
  }
  String? _messageId;
  String? _roomId;
  num? _senderId;
  num? _messageType;
  num? _messageStatus;
  num? _timestamp;
  Content? _content;
  dynamic _system;
  dynamic _attachment;
  dynamic _readUserIds;
LastMessage copyWith({  String? messageId,
  String? roomId,
  num? senderId,
  num? messageType,
  num? messageStatus,
  num? timestamp,
  Content? content,
  dynamic system,
  dynamic attachment,
  dynamic readUserIds,
}) => LastMessage(  messageId: messageId ?? _messageId,
  roomId: roomId ?? _roomId,
  senderId: senderId ?? _senderId,
  messageType: messageType ?? _messageType,
  messageStatus: messageStatus ?? _messageStatus,
  timestamp: timestamp ?? _timestamp,
  content: content ?? _content,
  system: system ?? _system,
  attachment: attachment ?? _attachment,
  readUserIds: readUserIds ?? _readUserIds,
);
  String? get messageId => _messageId;
  String? get roomId => _roomId;
  num? get senderId => _senderId;
  num? get messageType => _messageType;
  num? get messageStatus => _messageStatus;
  num? get timestamp => _timestamp;
  Content? get content => _content;
  dynamic get system => _system;
  dynamic get attachment => _attachment;
  dynamic get readUserIds => _readUserIds;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['messageId'] = _messageId;
    map['roomId'] = _roomId;
    map['senderId'] = _senderId;
    map['messageType'] = _messageType;
    map['messageStatus'] = _messageStatus;
    map['timestamp'] = _timestamp;
    if (_content != null) {
      map['content'] = _content?.toJson();
    }
    map['system'] = _system;
    map['attachment'] = _attachment;
    map['readUserIds'] = _readUserIds;
    return map;
  }

}

/// messageId : null
/// text : "你好"
/// type : 0
/// extra : {}

Content contentFromJson(String str) => Content.fromJson(json.decode(str));
String contentToJson(Content data) => json.encode(data.toJson());
class Content {
  Content({
      dynamic messageId, 
      String? text, 
      num? type, 
      dynamic extra,}){
    _messageId = messageId;
    _text = text;
    _type = type;
    _extra = extra;
}

  Content.fromJson(dynamic json) {
    _messageId = json['messageId'];
    _text = json['text'];
    _type = json['type'];
    _extra = json['extra'];
  }
  dynamic _messageId;
  String? _text;
  num? _type;
  dynamic _extra;
Content copyWith({  dynamic messageId,
  String? text,
  num? type,
  dynamic extra,
}) => Content(  messageId: messageId ?? _messageId,
  text: text ?? _text,
  type: type ?? _type,
  extra: extra ?? _extra,
);
  dynamic get messageId => _messageId;
  String? get text => _text;
  num? get type => _type;
  dynamic get extra => _extra;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['messageId'] = _messageId;
    map['text'] = _text;
    map['type'] = _type;
    map['extra'] = _extra;
    return map;
  }

}