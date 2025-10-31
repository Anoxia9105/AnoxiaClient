import 'dart:convert';
/// id : 1
/// fromUserId : 2
/// toUserId : 1
/// remark : "申请好友测试"
/// status : 0
/// createdAt : "2025-10-31T11:23:22"
/// updatedAt : "2025-10-31T11:23:22"
/// requestUser : {"createBy":null,"createTime":null,"updateBy":null,"updateTime":null,"remark":"申请好友测试","userId":null,"userName":null,"nickName":"测试用户","email":null,"phonenumber":null,"sex":null,"avatar":"https://ts2.tc.mm.bing.net/th/id/OIP-C.QQG4bvcAR3CJ0WeQULA9UQAAAA?rs=1&pid=ImgDetMain&o=7&rm=3","password":null,"status":"0","delFlag":null,"loginIp":null,"loginDate":null,"admin":false}

ContactRequest contactRequestFromJson(String str) => ContactRequest.fromJson(json.decode(str));
String contactRequestToJson(ContactRequest data) => json.encode(data.toJson());
class ContactRequest {
  ContactRequest({
      num? id, 
      num? fromUserId, 
      num? toUserId, 
      String? remark, 
      num? status, 
      String? createdAt, 
      String? updatedAt, 
      RequestUser? requestUser,}){
    _id = id;
    _fromUserId = fromUserId;
    _toUserId = toUserId;
    _remark = remark;
    _status = status;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _requestUser = requestUser;
}

  ContactRequest.fromJson(dynamic json) {
    _id = json['id'];
    _fromUserId = json['fromUserId'];
    _toUserId = json['toUserId'];
    _remark = json['remark'];
    _status = json['status'];
    _createdAt = json['createdAt'];
    _updatedAt = json['updatedAt'];
    _requestUser = json['requestUser'] != null ? RequestUser.fromJson(json['requestUser']) : null;
  }
  num? _id;
  num? _fromUserId;
  num? _toUserId;
  String? _remark;
  num? _status;
  String? _createdAt;
  String? _updatedAt;
  RequestUser? _requestUser;
ContactRequest copyWith({  num? id,
  num? fromUserId,
  num? toUserId,
  String? remark,
  num? status,
  String? createdAt,
  String? updatedAt,
  RequestUser? requestUser,
}) => ContactRequest(  id: id ?? _id,
  fromUserId: fromUserId ?? _fromUserId,
  toUserId: toUserId ?? _toUserId,
  remark: remark ?? _remark,
  status: status ?? _status,
  createdAt: createdAt ?? _createdAt,
  updatedAt: updatedAt ?? _updatedAt,
  requestUser: requestUser ?? _requestUser,
);
  num? get id => _id;
  num? get fromUserId => _fromUserId;
  num? get toUserId => _toUserId;
  String? get remark => _remark;
  num? get status => _status;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  RequestUser? get requestUser => _requestUser;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['fromUserId'] = _fromUserId;
    map['toUserId'] = _toUserId;
    map['remark'] = _remark;
    map['status'] = _status;
    map['createdAt'] = _createdAt;
    map['updatedAt'] = _updatedAt;
    if (_requestUser != null) {
      map['requestUser'] = _requestUser?.toJson();
    }
    return map;
  }

}

/// createBy : null
/// createTime : null
/// updateBy : null
/// updateTime : null
/// remark : "申请好友测试"
/// userId : null
/// userName : null
/// nickName : "测试用户"
/// email : null
/// phonenumber : null
/// sex : null
/// avatar : "https://ts2.tc.mm.bing.net/th/id/OIP-C.QQG4bvcAR3CJ0WeQULA9UQAAAA?rs=1&pid=ImgDetMain&o=7&rm=3"
/// password : null
/// status : "0"
/// delFlag : null
/// loginIp : null
/// loginDate : null
/// admin : false

RequestUser requestUserFromJson(String str) => RequestUser.fromJson(json.decode(str));
String requestUserToJson(RequestUser data) => json.encode(data.toJson());
class RequestUser {
  RequestUser({
      dynamic createBy, 
      dynamic createTime, 
      dynamic updateBy, 
      dynamic updateTime, 
      String? remark, 
      dynamic userId, 
      dynamic userName, 
      String? nickName, 
      dynamic email, 
      dynamic phonenumber, 
      dynamic sex, 
      String? avatar, 
      dynamic password, 
      String? status, 
      dynamic delFlag, 
      dynamic loginIp, 
      dynamic loginDate, 
      bool? admin,}){
    _createBy = createBy;
    _createTime = createTime;
    _updateBy = updateBy;
    _updateTime = updateTime;
    _remark = remark;
    _userId = userId;
    _userName = userName;
    _nickName = nickName;
    _email = email;
    _phonenumber = phonenumber;
    _sex = sex;
    _avatar = avatar;
    _password = password;
    _status = status;
    _delFlag = delFlag;
    _loginIp = loginIp;
    _loginDate = loginDate;
    _admin = admin;
}

  RequestUser.fromJson(dynamic json) {
    _createBy = json['createBy'];
    _createTime = json['createTime'];
    _updateBy = json['updateBy'];
    _updateTime = json['updateTime'];
    _remark = json['remark'];
    _userId = json['userId'];
    _userName = json['userName'];
    _nickName = json['nickName'];
    _email = json['email'];
    _phonenumber = json['phonenumber'];
    _sex = json['sex'];
    _avatar = json['avatar'];
    _password = json['password'];
    _status = json['status'];
    _delFlag = json['delFlag'];
    _loginIp = json['loginIp'];
    _loginDate = json['loginDate'];
    _admin = json['admin'];
  }
  dynamic _createBy;
  dynamic _createTime;
  dynamic _updateBy;
  dynamic _updateTime;
  String? _remark;
  dynamic _userId;
  dynamic _userName;
  String? _nickName;
  dynamic _email;
  dynamic _phonenumber;
  dynamic _sex;
  String? _avatar;
  dynamic _password;
  String? _status;
  dynamic _delFlag;
  dynamic _loginIp;
  dynamic _loginDate;
  bool? _admin;
RequestUser copyWith({  dynamic createBy,
  dynamic createTime,
  dynamic updateBy,
  dynamic updateTime,
  String? remark,
  dynamic userId,
  dynamic userName,
  String? nickName,
  dynamic email,
  dynamic phonenumber,
  dynamic sex,
  String? avatar,
  dynamic password,
  String? status,
  dynamic delFlag,
  dynamic loginIp,
  dynamic loginDate,
  bool? admin,
}) => RequestUser(  createBy: createBy ?? _createBy,
  createTime: createTime ?? _createTime,
  updateBy: updateBy ?? _updateBy,
  updateTime: updateTime ?? _updateTime,
  remark: remark ?? _remark,
  userId: userId ?? _userId,
  userName: userName ?? _userName,
  nickName: nickName ?? _nickName,
  email: email ?? _email,
  phonenumber: phonenumber ?? _phonenumber,
  sex: sex ?? _sex,
  avatar: avatar ?? _avatar,
  password: password ?? _password,
  status: status ?? _status,
  delFlag: delFlag ?? _delFlag,
  loginIp: loginIp ?? _loginIp,
  loginDate: loginDate ?? _loginDate,
  admin: admin ?? _admin,
);
  dynamic get createBy => _createBy;
  dynamic get createTime => _createTime;
  dynamic get updateBy => _updateBy;
  dynamic get updateTime => _updateTime;
  String? get remark => _remark;
  dynamic get userId => _userId;
  dynamic get userName => _userName;
  String? get nickName => _nickName;
  dynamic get email => _email;
  dynamic get phonenumber => _phonenumber;
  dynamic get sex => _sex;
  String? get avatar => _avatar;
  dynamic get password => _password;
  String? get status => _status;
  dynamic get delFlag => _delFlag;
  dynamic get loginIp => _loginIp;
  dynamic get loginDate => _loginDate;
  bool? get admin => _admin;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['createBy'] = _createBy;
    map['createTime'] = _createTime;
    map['updateBy'] = _updateBy;
    map['updateTime'] = _updateTime;
    map['remark'] = _remark;
    map['userId'] = _userId;
    map['userName'] = _userName;
    map['nickName'] = _nickName;
    map['email'] = _email;
    map['phonenumber'] = _phonenumber;
    map['sex'] = _sex;
    map['avatar'] = _avatar;
    map['password'] = _password;
    map['status'] = _status;
    map['delFlag'] = _delFlag;
    map['loginIp'] = _loginIp;
    map['loginDate'] = _loginDate;
    map['admin'] = _admin;
    return map;
  }

}