// Flutter Web 运行时接口配置。
//
// 默认留空：客户端会回退到 Dart 内置默认值（线上 chat.anoxia.cn / live.anoxia.cn）。
// anoxia-install.sh 部署时会把本文件替换为 /opt/anoxia/chat/runtime-config.js，
// 写入本机实际的接口地址，因此同一份 Web 打包产物可直接部署到任意机器。
//
// 可配置字段（均可选）：
//   httpBaseUrl    HTTP 接口基础地址，如 https://chat.example.com/api
//   wsBaseUrl      WebSocket 聊天地址，如 wss://chat.example.com/chat?token=
//   wsRoomBaseUrl  音视频信令地址，如 wss://live.example.com
//   qrUserBaseUrl  个人二维码前缀，如 https://chat.example.com/u/
//   qrGroupBaseUrl 群聊二维码前缀，如 https://chat.example.com/g/
window.__ANOXIA_CONFIG__ = window.__ANOXIA_CONFIG__ || {};
