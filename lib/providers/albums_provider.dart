import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../services/database_service.dart';

final albumsProvider = AsyncNotifierProvider<AlbumsNotifier, List<Album>>(AlbumsNotifier.new);

class AlbumsNotifier extends AsyncNotifier<List<Album>> {
  @override
  Future<List<Album>> build() async {
    return DatabaseService.getAlbums();
  }

  Future<void> addAlbum(String title, String? artist) async {
    final album = Album(title: title, artist: artist);
    await DatabaseService.insertAlbum(album);
    ref.invalidateSelf();
  }

  Future<void> deleteAlbum(int id) async {
    await DatabaseService.deleteAlbum(id);
    ref.invalidateSelf();
  }
}