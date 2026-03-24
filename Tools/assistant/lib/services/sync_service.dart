import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class SyncResult {
  final bool success;
  final String message;
  SyncResult({required this.success, required this.message});
}

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  static const _apiUrlKey = 'hostinger_api_url';
  static const _apiKeyKey = 'hostinger_api_key';
  static const _lastSyncKey = 'last_sync_time';

  Future<String?> get apiUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiUrlKey);
  }

  Future<String?> get apiKey async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<DateTime?> get lastSyncTime async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_lastSyncKey);
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }

  Future<void> saveSettings(
      {required String url, required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
    await prefs.setString(_apiKeyKey, key);
  }

  Future<SyncResult> testConnection() async {
    final url = await apiUrl;
    final key = await apiKey;
    if (url == null || url.isEmpty) {
      return SyncResult(success: false, message: 'API URL not configured');
    }
    try {
      final response = await http.get(
        Uri.parse('$url?action=ping'),
        headers: {'X-API-Key': key ?? ''},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return SyncResult(success: true, message: 'Connection successful!');
      }
      return SyncResult(
          success: false, message: 'Server error: ${response.statusCode}');
    } catch (e) {
      return SyncResult(success: false, message: 'Error: $e');
    }
  }

  Future<SyncResult> syncAll() async {
    final url = await apiUrl;
    final key = await apiKey;
    if (url == null || url.isEmpty) {
      return SyncResult(success: false, message: 'API URL not configured');
    }
    try {
      final data = await DatabaseService.instance.getAllDataForSync();
      final response = await http
          .post(
            Uri.parse('$url?action=sync'),
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': key ?? '',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
            _lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        return SyncResult(
            success: true, message: 'Synced successfully to Hostinger!');
      }
      return SyncResult(
          success: false, message: 'Sync failed: ${response.statusCode}');
    } catch (e) {
      return SyncResult(success: false, message: 'Sync error: $e');
    }
  }

  Future<SyncResult> pullFromCloud() async {
    final url = await apiUrl;
    final key = await apiKey;
    if (url == null || url.isEmpty) {
      return SyncResult(success: false, message: 'API URL not configured');
    }
    try {
      final response = await http.get(
        Uri.parse('$url?action=pull'),
        headers: {'X-API-Key': key ?? ''},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return SyncResult(success: true, message: 'Data pulled from cloud!');
      }
      return SyncResult(
          success: false, message: 'Pull failed: ${response.statusCode}');
    } catch (e) {
      return SyncResult(success: false, message: 'Pull error: $e');
    }
  }
}
