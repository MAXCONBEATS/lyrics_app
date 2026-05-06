import '../models/song.dart';
import '../models/section.dart';   // <-- добавлено
import 'telegram_service.dart';

class ExportImportService {
  /// Отправить одну песню в Telegram
  static Future<bool> sendSongToTelegram(Song song) async {
    final String lyrics = song.rawText?.isNotEmpty == true
        ? song.rawText!
        : song.sections.map((s) {
            final label = s.type == SectionType.custom
                ? (s.customLabel ?? 'Custom')
                : s.type.name;
            return '[$label]\n${s.text}';
          }).join('\n\n');

    final message = '${song.title}\n$lyrics';
    return await TelegramService.sendMessage(message);
  }

  /// Отправить все песни альбома последовательно
  static Future<void> sendAlbumToTelegram(List<Song> songs) async {
    for (final song in songs) {
      await sendSongToTelegram(song);
    }
  }
}