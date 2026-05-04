import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/album.dart';
import '../models/song.dart';

class ExportImportService {
  /// Экспорт одного альбома: создаётся папка с именем альбома, внутри JSON-файлы песен.
  static Future<void> exportAlbum(Album album, List<Song> songs) async {
    // Определяем временную директорию для подготовки
    final tempDir = await getTemporaryDirectory();
    final albumDir = Directory('${tempDir.path}/${_sanitizeFolderName(album.title)}');
    if (albumDir.existsSync()) {
      albumDir.deleteSync(recursive: true);
    }
    albumDir.createSync(recursive: true);

    for (var song in songs) {
      final jsonMap = song.toJson();
      final fileName = '${_sanitizeFileName(song.title)}.json';
      final file = File('${albumDir.path}/$fileName');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonMap));
    }

    // На ПК можно попросить пользователя выбрать папку для сохранения,
    // используем FilePicker для выбора папки назначения
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final selectedDir = await FilePicker.platform.getDirectoryPath();
      if (selectedDir != null) {
        final targetDir = Directory('$selectedDir/${_sanitizeFolderName(album.title)}');
        await _copyDirectory(albumDir, targetDir);
        // Открываем папку в проводнике (опционально)
      }
    } else {
      // Android/iOS — используем share для нескольких файлов
      final xFiles = <XFile>[];
      await for (var entity in albumDir.list()) {
        if (entity is File) {
          xFiles.add(XFile(entity.path));
        }
      }
      await Share.shareXFiles(xFiles, text: 'Альбом: ${album.title}');
    }
  }

  /// Импорт песен из JSON-файлов альбома (ожидается папка с JSON-файлами).
  static Future<List<Song>?> importSongsFromFolder() async {
    // Выбор папки
    String? folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath == null) return null;

    final dir = Directory(folderPath);
    if (!dir.existsSync()) return null;

    final List<Song> songs = [];
    for (var entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final content = await entity.readAsString();
        final json = jsonDecode(content);
        // Песни будут привязаны к новому альбому, albumId зададим позже
        songs.add(Song.fromJson(-1, json)); // -1 как placeholder
      }
    }
    return songs;
  }
  static Future<void> exportSingleSong(Song song) async {
  final jsonMap = song.toJson();
  final fileName = '${_sanitizeFileName(song.title)}.json';
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonMap));

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // На десктопах предложим сохранить через диалог
    final selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath != null) {
      final targetFile = File('$selectedPath/$fileName');
      await file.copy(targetFile.path);
    }
  } else {
    await Share.shareXFiles([XFile(file.path)], text: 'Текст песни: ${song.title}');
  }
}
static Future<Song?> importSingleSong() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return null;
  final file = File(result.files.single.path!);
  final content = await file.readAsString();
  final json = jsonDecode(content) as Map<String, dynamic>;
  return Song.fromJson(null, json); // albumId будет null, потом можно назначить
}

  static String _sanitizeFolderName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!target.existsSync()) target.createSync(recursive: true);
    for (var entity in source.listSync()) {
      if (entity is File) {
        entity.copySync('${target.path}/${entity.uri.pathSegments.last}');
      }
    }
  }
}