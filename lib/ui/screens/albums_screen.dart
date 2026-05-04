import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/albums_provider.dart';
import '../../services/export_import_service.dart';
import '../../services/database_service.dart';
import '../../models/album.dart';
import '../../models/song.dart';
import 'album_songs_screen.dart';
import 'songs_without_album_screen.dart';  // новый экран
import 'song_editor_screen.dart';


class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои альбомы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Импорт альбома',
            onPressed: _importAlbum(ref, context),
          ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            tooltip: 'Треки без альбома',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SongsWithoutAlbumScreen()),
            ),
          ),
        ],
      ),
      body: albumsAsync.when(
        data: (albums) => albums.isEmpty
            ? const Center(child: Text('Нет альбомов.\nНажмите +, чтобы создать'))
            : ListView.builder(
                itemCount: albums.length,
                itemBuilder: (_, i) {
                  final album = albums[i];
                  return ListTile(
                    title: Text(album.title),
                    subtitle: Text(album.artist ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => ref.read(albumsProvider.notifier).deleteAlbum(album.id!),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlbumSongsScreen(albumId: album.id!, albumTitle: album.title),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'addAlbum',
            child: const Icon(Icons.album),
            onPressed: () => _createAlbumDialog(context, ref),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> Function() _importAlbum(WidgetRef ref, BuildContext context) {
    return () async {
      final songs = await ExportImportService.importSongsFromFolder();
      if (songs != null && songs.isNotEmpty && context.mounted) {
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final ctrl = TextEditingController(text: 'Импортированный альбом');
            return AlertDialog(
              title: const Text('Название альбома'),
              content: TextField(controller: ctrl),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text),
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
        if (name != null && name.isNotEmpty) {
          final newAlbum = Album(title: name);
          final albumId = await DatabaseService.insertAlbum(newAlbum);
          for (var song in songs) {
            final fixedSong = Song(
              albumId: albumId,
              title: song.title,
              artist: song.artist,
              sections: song.sections,
              createdAt: song.createdAt,
              updatedAt: song.updatedAt,
            );
            await DatabaseService.insertSong(fixedSong);
          }
          ref.invalidate(albumsProvider);
        }
      }
    };
  }

  void _createAlbumDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый альбом'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: artistCtrl, decoration: const InputDecoration(labelText: 'Исполнитель (необязательно)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                ref.read(albumsProvider.notifier).addAlbum(titleCtrl.text, artistCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}