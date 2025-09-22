import 'dart:convert';
/// msg : "操作成功"
/// code : 200
/// data : {"createBy":"admin","createTime":"2025-08-26 17:25:52","updateBy":null,"updateTime":null,"remark":"管理员","params":{"@type":"java.util.HashMap"},"userId":1,"userName":"admin","nickName":"管理员","email":"anoxia@163.com","phonenumber":"15888888888","sex":"1","avatar":null,"password":"$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2","status":"0","delFlag":"0","loginIp":"127.0.0.1","loginDate":"2025-09-19T21:37:34.000+08:00","admin":true}

SysUser sysUserFromJson(String str) => SysUser.fromJson(json.decode(str));
String sysUserToJson(SysUser data) => json.encode(data.toJson());
class SysUser {
  SysUser({
      String? msg, 
      num? code, 
      Data? data,}){
    _msg = msg;
    _code = code;
    _data = data;
}

  SysUser.fromJson(dynamic json) {
    _msg = json['msg'];
    _code = json['code'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  String? _msg;
  num? _code;
  Data? _data;
SysUser copyWith({  String? msg,
  num? code,
  Data? data,
}) => SysUser(  msg: msg ?? _msg,
  code: code ?? _code,
  data: data ?? _data,
);
  String? get msg => _msg;
  num? get code => _code;
  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['msg'] = _msg;
    map['code'] = _code;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }

}

/// createBy : "admin"
/// createTime : "2025-08-26 17:25:52"
/// updateBy : null
/// updateTime : null
/// remark : "管理员"
/// params : {"@type":"java.util.HashMap"}
/// userId : 1
/// userName : "admin"
/// nickName : "管理员"
/// email : "anoxia@163.com"
/// phonenumber : "15888888888"
/// sex : "1"
/// avatar : null
/// password : "$2a$10$7JB720yubVSZvUI0rEqK/.VqGOZTH.ulu33dHOiBE8ByOhJIrdAu2"
/// status : "0"
/// delFlag : "0"
/// loginIp : "127.0.0.1"
/// loginDate : "2025-09-19T21:37:34.000+08:00"
/// admin : true

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      String? createBy, 
      String? createTime, 
      dynamic updateBy, 
      dynamic updateTime, 
      String? remark, 
      Params? params, 
      num? userId, 
      String? userName, 
      String? nickName, 
      String? email, 
      String? phonenumber, 
      String? sex, 
      dynamic avatar, 
      String? password, 
      String? status, 
      String? delFlag, 
      String? loginIp, 
      String? loginDate, 
      bool? admin,}){
    _createBy = createBy;
    _createTime = createTime;
    _updateBy = updateBy;
    _updateTime = updateTime;
    _remark = remark;
    _params = params;
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

  Data.fromJson(dynamic json) {
    _createBy = json['createBy'];
    _createTime = json['createTime'];
    _updateBy = json['updateBy'];
    _updateTime = json['updateTime'];
    _remark = json['remark'];
    _params = json['params'] != null ? Params.fromJson(json['params']) : null;
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
  String? _createBy;
  String? _createTime;
  dynamic _updateBy;
  dynamic _updateTime;
  String? _remark;
  Params? _params;
  num? _userId;
  String? _userName;
  String? _nickName;
  String? _email;
  String? _phonenumber;
  String? _sex;
  dynamic _avatar;
  String? _password;
  String? _status;
  String? _delFlag;
  String? _loginIp;
  String? _loginDate;
  bool? _admin;
Data copyWith({  String? createBy,
  String? createTime,
  dynamic updateBy,
  dynamic updateTime,
  String? remark,
  Params? params,
  num? userId,
  String? userName,
  String? nickName,
  String? email,
  String? phonenumber,
  String? sex,
  dynamic avatar,
  String? password,
  String? status,
  String? delFlag,
  String? loginIp,
  String? loginDate,
  bool? admin,
}) => Data(  createBy: createBy ?? _createBy,
  createTime: createTime ?? _createTime,
  updateBy: updateBy ?? _updateBy,
  updateTime: updateTime ?? _updateTime,
  remark: remark ?? _remark,
  params: params ?? _params,
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
  String? get createBy => _createBy;
  String? get createTime => _createTime;
  dynamic get updateBy => _updateBy;
  dynamic get updateTime => _updateTime;
  String? get remark => _remark;
  Params? get params => _params;
  num? get userId => _userId;
  String? get userName => _userName;
  String? get nickName => _nickName;
  String? get email => _email;
  String? get phonenumber => _phonenumber;
  String? get sex => _sex;
  dynamic get avatar => _avatar;
  String? get password => _password;
  String? get status => _status;
  String? get delFlag => _delFlag;
  String? get loginIp => _loginIp;
  String? get loginDate => _loginDate;
  bool? get admin => _admin;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['createBy'] = _createBy;
    map['createTime'] = _createTime;
    map['updateBy'] = _updateBy;
    map['updateTime'] = _updateTime;
    map['remark'] = _remark;
    if (_params != null) {
      map['params'] = _params?.toJson();
    }
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

/// @type : "java.util.HashMap"

Params paramsFromJson(String str) => Params.fromJson(json.decode(str));
String paramsToJson(Params data) => json.encode(data.toJson());
class Params {
  Params({
      String? type,}){
    _type = type;
}

  Params.fromJson(dynamic json) {
    _type = json['@type'];
  }
  String? _type;
Params copyWith({  String? type,
}) => Params(  type: type ?? _type,
);
  String? get type => _type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['@type'] = _type;
    return map;
  }

}