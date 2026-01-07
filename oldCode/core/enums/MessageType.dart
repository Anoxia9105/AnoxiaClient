
///
/// ChatMessage
///
enum MessageType {
  text,
  file, //纯文件
  image, //纯图片
  audio, //音频
  video, //视频
  quill, // 富文本（富内容）
  emoji, //表情
  system, // 系统通知
  aiReply, // AI回复（特化处理）
  //视频通话相关
  videoCall, // 视频通话请求
  videoAnswer, // 接听视频通话
  videoReject, // 拒绝视频通话
  videoHangup, // 挂断视频通话
  //语音通话相关
  voiceCall, // 发起语音通话
  voiceAnswer, // 接听语音通话
  voiceReject, // 拒绝语音通话
  voiceHangup, // 挂断语音通话
  signal, // SDP、ICE等信令
}
