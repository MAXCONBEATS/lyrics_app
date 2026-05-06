import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../services/database_service.dart';
import '../../services/export_import_service.dart';
import 'song_editor_screen.dart';
import 'albums_screen.dart';
import 'settings_screen.dart';

class TracksScreen extends ConsumerStatefulWidget {
  const TracksScreen({super.key});

  @override
  ConsumerState<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends ConsumerState<TracksScreen> {
  bool _filterInAlbum = false;
  List<Song> _songs = [];
  List<Album> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final songs = await DatabaseService.getAllSongsSortedByDate(
        inAlbum: _filterInAlbum ? true : null,
      );
      final albums = await DatabaseService.getAlbums();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _albums = albums;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все треки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки Telegram',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.album),
            tooltip: 'Альбомы',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlbumsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _filterInAlbum,
                  onChanged: (v) {
                    setState(() => _filterInAlbum = v ?? false);
                    _loadData();
                  },
                ),
                const Text('В альбоме'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                ? const Center(child: Text('Треков нет'))
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (_, i) {
                      final song = _songs[i];
                      // Ищем альбом для отображения
                      final albumTitle = song.albumId != null
                          ? _albums
                                .firstWhere(
                                  (a) => a.id == song.albumId,
                                  orElse: () => Album(title: ''),
                                )
                                .title
                          : '';
                      final subtitle = albumTitle.isNotEmpty
                          ? albumTitle
                          : null;

                      return ListTile(
                        title: Text(song.title),
                        subtitle: subtitle != null ? Text(subtitle) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.send),
                              tooltip: 'Отправить в Telegram',
                              onPressed: () => _sendSong(song),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Удалить',
                              onPressed: () => _confirmDelete(song),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SongEditorScreen(
                              song: song,
                              albumId: song.albumId,
                            ),
                          ),
                        ).then((_) => _loadData()),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SongEditorScreen(albumId: null)),
        ).then((_) => _loadData()),
      ),
    );
  }

  Future<void> _sendSong(Song song) async {
    try {
      final ok = await ExportImportService.sendSongToTelegram(song);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Трек отправлен'
                : 'Ошибка отправки. Проверьте интернет и настройки.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка сети: невозможно связаться с Telegram.\nПопробуйте включить VPN.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(Song song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить песню?'),
        content: Text('Удалить "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.deleteSong(song.id!);
      _loadData();
    }
  }
}
