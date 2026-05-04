import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../services/database_service.dart';
import '../../services/export_import_service.dart';
import 'song_editor_screen.dart';

class SongsWithoutAlbumScreen extends ConsumerStatefulWidget {
  const SongsWithoutAlbumScreen({super.key});

  @override
  ConsumerState<SongsWithoutAlbumScreen> createState() =>
      _SongsWithoutAlbumScreenState();
}

class _SongsWithoutAlbumScreenState
    extends ConsumerState<SongsWithoutAlbumScreen> {
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = DatabaseService.getSongsWithoutAlbum();
  }

  void _refresh() {
    setState(() {
      _songsFuture = DatabaseService.getSongsWithoutAlbum();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Треки без альбома'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Импортировать трек',
            onPressed: () async {
              final song = await ExportImportService.importSingleSong();
              if (song != null && mounted) {
                await DatabaseService.insertSong(song);
                _refresh();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return const Center(child: Text('Все треки уже в альбомах'));
          }
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (_, i) {
              final song = songs[i];
              return ListTile(
                title: Text(song.title),
                subtitle: Text(song.artist ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.file_download),
                      tooltip: 'Экспорт',
                      onPressed: () =>
                          ExportImportService.exportSingleSong(song),
                    ),
                    IconButton(
                      icon: const Icon(Icons.drive_file_move),
                      tooltip: 'Переместить в альбом',
                      onPressed: () => _moveToAlbumDialog(song.id!),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Удалить',
                      onPressed: () => _confirmDeleteSong(song.id!, song.title),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SongEditorScreen(song: song, albumId: null),
                    ),
                  ).then((_) => _refresh());
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SongEditorScreen(albumId: null),
            ),
          ).then((_) => _refresh());
        },
      ),
    );
  }

  Future<void> _moveToAlbumDialog(int songId) async {
    final albums = await DatabaseService.getAlbums();
    if (!mounted) return;
    final album = await showDialog<Album>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Выберите альбом'),
          children: albums.map((a) => SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, a),
            child: Text(a.title),
          )).toList(),
        );
      },
    );
    if (album != null && mounted) {
      await DatabaseService.moveSongToAlbum(songId, album.id);
      _refresh();
    }
  }

  Future<void> _confirmDeleteSong(int songId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить песню?'),
        content: Text('Удалить "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.deleteSong(songId);
      _refresh();
    }
  }
}