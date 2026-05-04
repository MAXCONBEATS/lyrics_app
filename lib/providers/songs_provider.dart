import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../services/database_service.dart';

final songsForAlbumProvider =
    FutureProvider.family<List<Song>, int>((ref, albumId) async {
  return DatabaseService.getSongsForAlbum(albumId);
});