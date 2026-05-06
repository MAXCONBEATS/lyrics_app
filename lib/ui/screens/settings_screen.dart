import 'package:flutter/material.dart';
import '../../services/telegram_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _tokenCtrl = TextEditingController();
  final _chatIdCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final token = await TelegramService.getToken();
    final chatId = await TelegramService.getChatId();
    _tokenCtrl.text = token ?? '';
    _chatIdCtrl.text = chatId ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await TelegramService.saveCredentials(_tokenCtrl.text, _chatIdCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки сохранены')),
    );
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _chatIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки Telegram')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _tokenCtrl,
                    decoration: const InputDecoration(labelText: 'Bot Token'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _chatIdCtrl,
                    decoration: const InputDecoration(labelText: 'Chat ID'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ),
    );
  }
}