import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatEncrypt {
  final encrypt.Encrypter _encrypter;
  final encrypt.IV _iv;

  ChatEncrypt(String key) {
    final keyBytes = encrypt.Key.fromUtf8(key.padRight(32, ' '));
    _encrypter = encrypt.Encrypter(encrypt.AES(keyBytes, mode: encrypt.AESMode.cbc));
    _iv = encrypt.IV.fromUtf8('1234567890123456'); // 16 bytes IV
  }

  // Encrypt a message
  String encryptMessage(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return base64Encode(encrypted.bytes);
  }


  // Generate a random encryption key
  String generateKey() {
    final key = encrypt.Key.fromSecureRandom(32); // 256 bits
    return base64Encode(key.bytes);
  }

  // Load dummy data for testing
  void loadDummyData() {
    final testKey = generateKey();
    final encryptor = ChatEncrypt(testKey);
    
    // Test encryption and decryption
    String originalMessage = "Hello, this is a secret message!";
    String encryptedMsg = encryptor.encryptMessage(originalMessage);
    String decryptedMsg = encryptor.decryptMessage(encryptedMsg);
    
    print("Original: $originalMessage");
    print("Encrypted: $encryptedMsg");
    print("Decrypted: $decryptedMsg");
  }
}