import 'package:shared_preferences/shared_preferences.dart';

// These are the user's own API credentials from my.telegram.org
// (API development tools). SannDrive never ships or shares any.
class TgCredentials {
  final int apiId;
  final String apiHash;

  const TgCredentials({required this.apiId, required this.apiHash});
}

int? parseApiId(String input) {
  final v = int.tryParse(input.trim());
  return (v == null || v <= 0) ? null : v;
}

bool isValidApiHash(String input) =>
    RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(input.trim());

class CredentialsStore {
  static const _idKey = 'tg_api_id';
  static const _hashKey = 'tg_api_hash';

  Future<TgCredentials?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_idKey);
      final hash = prefs.getString(_hashKey);
      if (id == null || id <= 0 || hash == null || hash.isEmpty) return null;
      return TgCredentials(apiId: id, apiHash: hash);
    } catch (_) {
      return null;
    }
  }

  Future<bool> get hasCredentials async => (await load()) != null;

  Future<void> save(TgCredentials creds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_idKey, creds.apiId);
    await prefs.setString(_hashKey, creds.apiHash);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_idKey);
    await prefs.remove(_hashKey);
  }
}
