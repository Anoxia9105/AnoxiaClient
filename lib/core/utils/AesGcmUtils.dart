import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class AesGcmUtils {
  static const int ivLength = 12; // 12-byte IV for GCM
  static const int tagLength = 16; // 128-bit tag = 16 bytes

  static final _aesGcm128 = AesGcm.with128bits();
  static final _aesGcm256 = AesGcm.with256bits();

  static AesGcm _algoForKey(List<int> key) {
    // Recommend 16 or 32-byte keys. 24-byte (AES-192) may not be supported by the package.
    if (key.length == 16) return _aesGcm128;
    if (key.length == 32) return _aesGcm256;
    throw ArgumentError('Unsupported AES key length: ${key.length}. Use 16 or 32 bytes.');
  }

  /// Encrypts and returns Base64(IV + CipherText + Tag)
  /// 加密
  static Future<String> encrypt(String plainText, List<int> secretKey) async {
    final algorithm = _algoForKey(secretKey);
    final iv = Uint8List(ivLength);
    final rnd = Random.secure();
    for (var i = 0; i < ivLength; i++) {
      iv[i] = rnd.nextInt(256);
    }

    final secret = SecretKey(secretKey);
    final secretBox = await algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secret,
      nonce: iv, // pass IV directly
    );

    // Concatenate IV + cipherText + tag to match Java output
    final out = Uint8List(iv.length + secretBox.cipherText.length + tagLength);
    out.setAll(0, iv);
    out.setAll(iv.length, secretBox.cipherText);
    out.setAll(iv.length + secretBox.cipherText.length, secretBox.mac.bytes);

    return base64Encode(out);
  }

  /// Decrypts from Base64(IV + CipherText + Tag)
  /// 解密
  static Future<String> decrypt(String base64, List<int> secretKey) async {
    final algorithm = _algoForKey(secretKey);
    final data = base64Decode(base64);

    if (data.length < ivLength + tagLength) {
      throw ArgumentError('Invalid input: too short for IV + tag.');
    }

    final iv = data.sublist(0, ivLength);
    final cipherAndTag = data.sublist(ivLength);

    if (cipherAndTag.length < tagLength) {
      throw ArgumentError('Invalid input: missing tag.');
    }

    final cipherTextLen = cipherAndTag.length - tagLength;
    final cipherText = cipherAndTag.sublist(0, cipherTextLen);
    final tag = cipherAndTag.sublist(cipherTextLen);

    final secret = SecretKey(secretKey);
    final secretBox = SecretBox(
      cipherText,
      nonce: iv,        // pass IV directly
      mac: Mac(tag),    // provide the 16-byte GCM tag
    );

    final plainBytes = await algorithm.decrypt(secretBox, secretKey: secret);
    return utf8.decode(plainBytes);
  }
}
