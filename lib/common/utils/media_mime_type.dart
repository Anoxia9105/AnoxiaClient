/// Resolves the MIME type used by V6 media attachments and multipart uploads.
String mediaMimeTypeForName(String fileName, {String? declaredType}) {
  final normalizedDeclared = declaredType?.trim().toLowerCase();
  if (normalizedDeclared != null && normalizedDeclared.contains('/')) {
    return normalizedDeclared;
  }
  final dot = fileName.lastIndexOf('.');
  final extension = dot >= 0 && dot < fileName.length - 1
      ? fileName.substring(dot + 1).toLowerCase()
      : '';
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'bmp' => 'image/bmp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'tif' || 'tiff' => 'image/tiff',
    'avif' => 'image/avif',
    'svg' => 'image/svg+xml',
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'csv' => 'text/csv',
    'json' => 'application/json',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'zip' => 'application/zip',
    'rar' => 'application/vnd.rar',
    '7z' => 'application/x-7z-compressed',
    'mp3' => 'audio/mpeg',
    'm4a' => 'audio/mp4',
    'wav' => 'audio/wav',
    'ogg' => 'audio/ogg',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    'mkv' => 'video/x-matroska',
    'avi' => 'video/x-msvideo',
    'm4v' => 'video/x-m4v',
    'flv' => 'video/x-flv',
    '3gp' => 'video/3gpp',
    'wmv' => 'video/x-ms-wmv',
    'mpeg' || 'mpg' => 'video/mpeg',
    _ => 'application/octet-stream',
  };
}
