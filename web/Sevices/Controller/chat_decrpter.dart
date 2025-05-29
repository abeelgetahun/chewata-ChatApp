import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatDecrypter {
  final encrypt.Encrypter _encrypter;
  final encrypt.IV _iv;

  ChatDecrypter(String key) {
    final keyBytes = encrypt.Key.fromUtf8(key.padRight(32, ' ')); // 256 bits key
    _encrypter = encrypt.Encrypter(encrypt.AES(keyBytes, mode: encrypt.AESMode.cbc));
    _iv = encrypt.IV.fromUtf8('1234567890123456'); // 16 bytes IV
  }


  // Batch decrypt multiple messages
  List<String> decryptBatch(List<String> encryptedMessages) {
    return encryptedMessages
        .where((msg) => isValidEncryptedFormat(msg))
        .map((msg) => decryptMessage(msg))
        .toList();
  }

  // Load dummy data for testing
  void loadDummyData() {
    final testKey = "mysecretkey1234567890123456"; // 32 chars for 256 bits
    final decrypter = ChatDecrypter(testKey);

    // Dummy encrypted messages
    List<String> encryptedMessages = [
      base64Encode(encrypt.Encrypted.fromUtf8("Hello, secret!").bytes), // Valid
      "invalid_base64_data", // Invalid
      base64Encode(encrypt.Encrypted.fromUtf8("Another secret!").bytes), // Valid
    ];

    // Test decryption
    List<String> decryptedResults = decrypter.decryptBatch(encryptedMessages);
    for (int i = 0; i < decryptedResults.length; i++) {
      print("Message $i: $decryptedResults[i]");
    }
  }
}