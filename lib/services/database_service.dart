import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/album.dart';
import '../models/song.dart';
import '../models/section.dart';

class DatabaseService {
  static Database? _database;
  static const _databaseVersion = 4;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lyrics.db');

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

static Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE albums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE songs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      album_id INTEGER,
      title TEXT NOT NULL,
      raw_text TEXT DEFAULT '',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE SET NULL
    )
  ''');

    await db.execute('''
      CREATE TABLE sections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        text TEXT NOT NULL,
        custom_label TEXT,
        sort_order INTEGER NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Миграция: album_id становится nullable
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE songs_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            album_id INTEGER,
            title TEXT NOT NULL,
            artist TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE SET NULL
          )
        ''');
        await txn.execute('''
          INSERT INTO songs_new (id, album_id, title, artist, created_at, updated_at)
          SELECT id, album_id, title, artist, created_at, updated_at FROM songs
        ''');
        await txn.execute('DROP TABLE IF EXISTS songs');
        await txn.execute('ALTER TABLE songs_new RENAME TO songs');
      });
    }

    if (oldVersion < 3) {
      // Миграция: добавление колонки raw_text
      await db.execute('ALTER TABLE songs ADD COLUMN raw_text TEXT DEFAULT ""');
    }
  }

  // ==================== Альбомы ====================

  static Future<int> insertAlbum(Album album) async {
    final db = await database;
    return db.insert('albums', album.toMap());
  }

  static Future<List<Album>> getAlbums() async {
    final db = await database;
    final maps = await db.query('albums', orderBy: 'created_at DESC');
    return maps.map((m) => Album.fromMap(m)).toList();
  }

  static Future<void> deleteAlbum(int id) async {
    final db = await database;
    // Песни, связанные с этим альбомом, получат album_id = NULL
    // из-за ON DELETE SET NULL
    await db.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Песни ====================

  static Future<int> insertSong(Song song) async {
    final db = await database;
    final songId = await db.insert('songs', song.toMap());
    // Секции больше не вставляем, текст хранится в raw_text
    return songId;
  }

  static Future<List<Song>> getSongsForAlbum(int albumId) async {
    final db = await database;
    final songMaps = await db.query(
      'songs',
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'title',
    );
    return _songsFromMaps(db, songMaps);
  }

  static Future<List<Song>> getSongsWithoutAlbum() async {
    final db = await database;
    final songMaps = await db.query(
      'songs',
      where: 'album_id IS NULL',
      orderBy: 'title',
    );
    return _songsFromMaps(db, songMaps);
  }

  static Future<List<Song>> getAllSongs() async {
    final db = await database;
    final songMaps = await db.query('songs', orderBy: 'title');
    return _songsFromMaps(db, songMaps);
  }

  static Future<List<Song>> _songsFromMaps(
    Database db,
    List<Map<String, dynamic>> songMaps,
  ) async {
    List<Song> songs = [];
    for (var sm in songMaps) {
      final sectionMaps = await db.query(
        'sections',
        where: 'song_id = ?',
        whereArgs: [sm['id']],
        orderBy: 'sort_order',
      );
      final sections = sectionMaps.map((s) => SongSection.fromMap(s)).toList();
      songs.add(Song.fromMap(sm, sections: sections));
    }
    return songs;
  }

  static Future<void> updateSong(Song song) async {
    final db = await database;
    await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
    // После перехода на raw_text очищаем старые секции, чтобы не было мусора
    await db.delete('sections', where: 'song_id = ?', whereArgs: [song.id]);
  }

  static Future<void> deleteSong(int id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Song?> getSong(int id) async {
    final db = await database;
    final maps = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final sm = maps.first;
    final sectionMaps = await db.query(
      'sections',
      where: 'song_id = ?',
      whereArgs: [id],
      orderBy: 'sort_order',
    );
    final sections = sectionMaps.map((s) => SongSection.fromMap(s)).toList();
    return Song.fromMap(sm, sections: sections);
  }

  static Future<void> moveSongToAlbum(int songId, int? albumId) async {
    final db = await database;
    await db.update(
      'songs',
      {'album_id': albumId},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  static Future<List<String>> getDistinctArtists() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT artist FROM songs WHERE artist IS NOT NULL AND artist != "" ORDER BY artist',
    );
    return result.map((r) => r['artist'] as String).toList();
  }

  static Future<List<Song>> getAllSongsSortedByDate({bool? inAlbum}) async {
    final db = await database;
    String? where;
    List<Object?>? whereArgs;
    if (inAlbum == true) {
      where = 'album_id IS NOT NULL';
    } else if (inAlbum == false) {
      where = 'album_id IS NULL';
    }
    final songMaps = await db.query(
      'songs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return _songsFromMaps(db, songMaps);
  }
}
