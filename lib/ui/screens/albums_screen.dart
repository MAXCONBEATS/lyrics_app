// lib/ui/screens/albums_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/albums_provider.dart';
import '../../models/album.dart';
import 'album_songs_screen.dart';

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои альбомы'),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _createAlbumDialog(context, ref),
      ),
    );
  }

  void _createAlbumDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый альбом'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                ref.read(albumsProvider.notifier).addAlbum(titleCtrl.text);
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