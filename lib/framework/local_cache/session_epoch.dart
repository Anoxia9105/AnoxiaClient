/// 异步请求和数据库写入的会话代次。Token 改变时旧任务立即失效。
class SessionEpoch {
  static final instance = SessionEpoch();

  int _value = 0;
  int get value => _value;
  void advance() => _value++;
}
