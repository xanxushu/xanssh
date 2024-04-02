import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

class MyEncryptor {
  late final encrypt.Key key;
  late final encrypt.Encrypter encrypter;
  late final encrypt.IV iv;

  // 从安全随机密钥生成实例
  MyEncryptor.fromSecureRandomKey([int keyLength = 32]) {
    final secureRandomKey = _generateSecureRandomKey(keyLength);
    key = encrypt.Key(secureRandomKey);
    iv = encrypt.IV.fromLength(16);
    encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  // 从Base64编码的密钥字符串生成实例
  MyEncryptor.fromBase64EncodedKey(String base64Key, {String? base64Iv}) {
    final keyBytes = base64Decode(base64Key);
    final ivBytes = base64Iv != null ? base64Decode(base64Iv) : Uint8List(16); // 如果没有提供IV，则默认使用空字节
    key = encrypt.Key(keyBytes);
    iv = encrypt.IV(ivBytes);
    encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  Uint8List _generateSecureRandomKey(int length) {
    final rand = Random.secure();
    final bytes = List<int>.generate(length, (_) => rand.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  String encryptData(String data) {
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedData) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // 获取密钥的Base64编码字符串，用于存储和交换
  String getBase64EncodedKey() => base64Encode(key.bytes);
  // 可选：获取IV的Base64编码字符串
  String getBase64EncodedIV() => base64Encode(iv.bytes);
}
