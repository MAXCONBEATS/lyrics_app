import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../services/database_service.dart';
import '../../services/export_import_service.dart';
import '../../providers/songs_provider.dart';
import 'song_editor_screen.dart';

class AlbumSongsScreen extends ConsumerWidget {
  final int albumId;
  final String albumTitle;

  const AlbumSongsScreen({super.key, required this.albumId, required this.albumTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsForAlbumProvider(albumId));

    return Scaffold(
      appBar: AppBar(
        title: Text(albumTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Экспорт альбома',
            onPressed: () async {
              final songs = await ref.read(songsForAlbumProvider(albumId).future);
              await ExportImportService.exportAlbum(
                Album(id: albumId, title: albumTitle, artist: ''),
                songs,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Добавить существующий трек',
            onPressed: () => _addExistingSong(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Импорт трека',
            onPressed: () async {
              final song = await ExportImportService.importSingleSong();
              if (song != null) {
                song.albumId = albumId;
                await DatabaseService.insertSong(song);
                ref.invalidate(songsForAlbumProvider(albumId));
              }
            },
          ),
        ],
      ),
      body: songsAsync.when(
        data: (songs) => songs.isEmpty
            ? const Center(child: Text('В альбоме ещё нет песен'))
            : ListView.builder(
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
                          tooltip: 'Экспорт трека',
                          onPressed: () =>
                              ExportImportService.exportSingleSong(song),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Удалить трек',
                          onPressed: () => _confirmDeleteSong(context, ref, song),
                        ),
                      ],
                    ),
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SongEditorScreen(song: song, albumId: albumId),
                          ),
                        ).then(
                          (_) => ref.invalidate(songsForAlbumProvider(albumId)),
                        ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongEditorScreen(albumId: albumId),
          ),
        ).then((_) => ref.invalidate(songsForAlbumProvider(albumId))),
      ),
    );
  }

  Future<void> _addExistingSong(BuildContext context, WidgetRef ref) async {
    final orphanSongs = await DatabaseService.getSongsWithoutAlbum();
    if (!context.mounted) return;

    if (orphanSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет треков без альбома')),
      );
      return;
    }

    final selected = <Song>[];
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить треки в альбом'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: orphanSongs.map((song) {
                    final isSelected = selected.contains(song);
                    return CheckboxListTile(
                      title: Text(song.title),
                      subtitle: Text(song.artist ?? ''),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selected.add(song);
                          } else {
                            selected.remove(song);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          for (var song in selected) {
                            await DatabaseService.moveSongToAlbum(song.id!, albumId);
                          }
                          ref.invalidate(songsForAlbumProvider(albumId));
                          Navigator.pop(ctx);
                        },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSong(BuildContext context, WidgetRef ref, Song song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить песню?'),
        content: Text('Удалить "${song.title}"?'),
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
      await DatabaseService.deleteSong(song.id!);
      ref.invalidate(songsForAlbumProvider(albumId));
    }
  }
}