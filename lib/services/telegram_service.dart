import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TelegramService {
  static const _tokenKey = 'telegram_bot_token';
  static const _chatIdKey = 'telegram_chat_id';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getChatId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chatIdKey);
  }

  static Future<void> saveCredentials(String token, String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_chatIdKey, chatId);
  }

  static Future<bool> sendMessage(String text) async {
    final token = await getToken();
    final chatId = await getChatId();
    if (token == null || chatId == null) return false;

    final uri = Uri.parse('https://api.telegram.org/bot$token/sendMessage');
    final response = await http.post(uri, body: {
      'chat_id': chatId,
      'text': text,
      'parse_mode': 'Markdown',
    });

    return response.statusCode == 200;
  }
}