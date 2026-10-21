import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

/// Secure password hashing and verification utility using PBKDF2 with HMAC-SHA256 and salted hashes.
class PasswordHasher {
  final Pbkdf2 _pbkdf2;

  PasswordHasher({int iterations = 10000, int bits = 256})
      : _pbkdf2 = Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: iterations,
          bits: bits,
        );

  /// Hashes a plain-text password using a cryptographically secure random 16-byte salt.
  /// Returns a string in the format: `salt_hex$hash_hex`.
  Future<String> hashPassword(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final secretKey = SecretKey(utf8.encode(password));
    final derivedKey = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    final keyBytes = await derivedKey.extractBytes();
    final saltHex = _toHex(salt);
    final hashHex = _toHex(keyBytes);
    return '$saltHex\$$hashHex';
  }

  /// Verifies a plain-text password against a previously generated `salt_hex$hash_hex` string.
  Future<bool> verifyPassword({
    required String password,
    required String storedHash,
  }) async {
    try {
      final parts = storedHash.split('\$');
      if (parts.length != 2) return false;

      final salt = _fromHex(parts[0]);
      final expectedHashHex = parts[1];

      final secretKey = SecretKey(utf8.encode(password));
      final derivedKey = await _pbkdf2.deriveKey(
        secretKey: secretKey,
        nonce: salt,
      );
      final keyBytes = await derivedKey.extractBytes();
      final computedHashHex = _toHex(keyBytes);

      return computedHashHex == expectedHashHex;
    } catch (_) {
      return false;
    }
  }

  static String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static List<int> _fromHex(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
