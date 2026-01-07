import 'dart:convert';

/// contactUser : {"createBy":null,"createTime":null,"updateBy":null,"updateTime":null,"remark":null,"userId":null,"userName":null,"nickName":"测试用户2","email":"anoxia@qq.com","phonenumber":"15666666666","sex":"1","avatar":"","password":null,"status":"0","delFlag":null,"loginIp":null,"loginDate":null,"admin":false}
/// id : null
/// userId : null
/// contactId : 3
/// status : 0
/// remark : null
/// createdAt : "2025-10-20T11:05:44"
/// updatedAt : "2025-10-20T11:05:44"

Contact contactFromJson(String str) => Contact.fromJson(json.decode(str));
String contactToJson(Contact data) => json.encode(data.toJson());
class Contact{
  Contact({
      ContactUser? contactUser, 
      dynamic id, 
      dynamic userId, 
      num? contactId, 
      num? status, 
      dynamic remark, 
      String? createdAt, 
      String? updatedAt,}){
    _contactUser = contactUser;
    _id = id;
    _userId = userId;
    _contactId = contactId;
    _status = status;
    _remark = remark;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
}

  Contact.fromJson(dynamic json) {
    _contactUser = json['contactUser'] != null ? ContactUser.fromJson(json['contactUser']) : null;
    _id = json['id'];
    _userId = json['userId'];
    _contactId = json['contactId'];
    _status = json['status'];
    _remark = json['remark'];
    _createdAt = json['createdAt'];
    _updatedAt = json['updatedAt'];
  }
  ContactUser? _contactUser;
  dynamic _id;
  dynamic _userId;
  num? _contactId;
  num? _status;
  dynamic _remark;
  String? _createdAt;
  String? _updatedAt;
Contact copyWith({  ContactUser? contactUser,
  dynamic id,
  dynamic userId,
  num? contactId,
  num? status,
  dynamic remark,
  String? createdAt,
  String? updatedAt,
}) => Contact(  contactUser: contactUser ?? _contactUser,
  id: id ?? _id,
  userId: userId ?? _userId,
  contactId: contactId ?? _contactId,
  status: status ?? _status,
  remark: remark ?? _remark,
  createdAt: createdAt ?? _createdAt,
  updatedAt: updatedAt ?? _updatedAt,
);
  ContactUser? get contactUser => _contactUser;
  dynamic get id => _id;
  dynamic get userId => _userId;
  num? get contactId => _contactId;
  num? get status => _status;
  dynamic get remark => _remark;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_contactUser != null) {
      map['contactUser'] = _contactUser?.toJson();
    }
    map['id'] = _id;
    map['userId'] = _userId;
    map['contactId'] = _contactId;
    map['status'] = _status;
    map['remark'] = _remark;
    map['createdAt'] = _createdAt;
    map['updatedAt'] = _updatedAt;
    return map;
  }

}

/// createBy : null
/// createTime : null
/// updateBy : null
/// updateTime : null
/// remark : null
/// userId : null
/// userName : null
/// nickName : "测试用户2"
/// email : "anoxia@qq.com"
/// phonenumber : "15666666666"
/// sex : "1"
/// avatar : ""
/// password : null
/// status : "0"
/// delFlag : null
/// loginIp : null
/// loginDate : null
/// admin : false

ContactUser contactUserFromJson(String str) => ContactUser.fromJson(json.decode(str));
String contactUserToJson(ContactUser data) => json.encode(data.toJson());
class ContactUser {
  ContactUser({
      dynamic createBy, 
      dynamic createTime, 
      dynamic updateBy, 
      dynamic updateTime, 
      dynamic remark, 
      dynamic userId, 
      dynamic userName, 
      String? nickName, 
      String? email, 
      String? phonenumber, 
      String? sex, 
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

  ContactUser.fromJson(dynamic json) {
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
  dynamic _remark;
  dynamic _userId;
  dynamic _userName;
  String? _nickName;
  String? _email;
  String? _phonenumber;
  String? _sex;
  String? _avatar;
  dynamic _password;
  String? _status;
  dynamic _delFlag;
  dynamic _loginIp;
  dynamic _loginDate;
  bool? _admin;
ContactUser copyWith({  dynamic createBy,
  dynamic createTime,
  dynamic updateBy,
  dynamic updateTime,
  dynamic remark,
  dynamic userId,
  dynamic userName,
  String? nickName,
  String? email,
  String? phonenumber,
  String? sex,
  String? avatar,
  dynamic password,
  String? status,
  dynamic delFlag,
  dynamic loginIp,
  dynamic loginDate,
  bool? admin,
}) => ContactUser(  createBy: createBy ?? _createBy,
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
  dynamic get remark => _remark;
  dynamic get userId => _userId;
  dynamic get userName => _userName;
  String? get nickName => _nickName;
  String? get email => _email;
  String? get phonenumber => _phonenumber;
  String? get sex => _sex;
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

  @override
  String toString() {
    return 'ContactUser{_createBy: $_createBy, _createTime: $_createTime, _updateBy: $_updateBy, _updateTime: $_updateTime, _remark: $_remark, _userId: $_userId, _userName: $_userName, _nickName: $_nickName, _email: $_email, _phonenumber: $_phonenumber, _sex: $_sex, _avatar: $_avatar, _password: $_password, _status: $_status, _delFlag: $_delFlag, _loginIp: $_loginIp, _loginDate: $_loginDate, _admin: $_admin}';
  }
}