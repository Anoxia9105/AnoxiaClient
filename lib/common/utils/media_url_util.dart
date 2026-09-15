/// 媒体 URL 判定工具
///
/// 「乐观发送」链路里附件 URL 会经历两个阶段：先放本地文件路径/空字符串，
/// 上传成功后才被替换成服务器地址。凡是"能不能当作服务器资源处理"的判断
/// 都收敛到这里，避免各处自行 `startsWith('http')` 出现口径不一致。
library;

/// 是否为服务器可访问的媒体地址
///
/// 只有 `http://` / `https://` 才算；本地绝对路径（`/data/user/0/...`、
/// `C:\Users\...`）、`file://`、`blob:`、空串都返回 false。
bool isRemoteMediaUrl(String? url) =>
    url != null &&
    url.isNotEmpty &&
    (url.startsWith('http://') || url.startsWith('https://'));

/// 是否为「尚未上传完成」的本地媒体
///
/// 这类 URL 不能发给服务端、不能走下载、不能进磁盘缓存。
bool isPendingLocalMediaUrl(String? url) =>
    url != null && url.isNotEmpty && !isRemoteMediaUrl(url);

/// 本地待上传媒体的占位地址
///
/// Web 端 `PlatformFile.path` 为 null，但 `MessagePayload.mediaAttachments`
/// 只收集 url 非空的附件——没有地址本地气泡就会整个渲染不出来。这里给一个
/// 明确非 http 的合成地址，`AttachmentImageView` 会转而用内存 bytes 渲染。
/// 它只存在于内存中的乐观消息里（不会落库、上传完成前不会发给服务端）。
String localPendingMediaUrl(String id) => 'local-pending://$id';
