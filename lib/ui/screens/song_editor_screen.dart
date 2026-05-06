import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../services/database_service.dart';
import '../../services/export_import_service.dart';
import '../../providers/songs_provider.dart';

const _sectionLabels = [
  'Intro', 'Verse', 'PreChorus', 'Chorus', 'Post-Chorus',
  'Bridge', 'Outro', 'Drop', 'Skit', 'Refrain', 'Interlude',
];

class SongEditorScreen extends ConsumerStatefulWidget {
  final Song? song;
  final int? albumId;

  const SongEditorScreen({super.key, this.song, this.albumId});

  @override
  ConsumerState<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends ConsumerState<SongEditorScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController lyricsCtrl;
  final _formKey = GlobalKey<FormState>();
  List<Album> _albums = [];
  int? _selectedAlbumId;

  bool get isEditing => widget.song != null;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.song?.title ?? '');

    String initialLyrics = widget.song?.rawText ?? '';
    if (initialLyrics.isEmpty &&
        widget.song != null &&
        widget.song!.sections.isNotEmpty) {
      initialLyrics = widget.song!.sections.map((s) {
        final label = s.type.name;
        return '[$label]\n${s.text}';
      }).join('\n\n');
    }
    lyricsCtrl = TextEditingController(text: initialLyrics);

    _selectedAlbumId = widget.song?.albumId ?? widget.albumId;
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    _albums = await DatabaseService.getAlbums();
    setState(() {});
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    lyricsCtrl.dispose();
    super.dispose();
  }

  void _insertSectionLabel(String label) {
    final text = lyricsCtrl.text;
    final selection = lyricsCtrl.selection;
    int pos = selection.isValid ? selection.start : text.length;

    final needsNewlineBefore = pos > 0 && text[pos - 1] != '\n';
    final prefix = needsNewlineBefore ? '\n' : '';
    final suffix = '\n';

    final insert = '$prefix[$label]$suffix';
    final newText = text.replaceRange(pos, pos, insert);
    final newPos = pos + insert.length;

    lyricsCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newPos),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final song = Song(
      id: widget.song?.id,
      albumId: _selectedAlbumId,
      title: titleCtrl.text,
      sections: [],
      rawText: lyricsCtrl.text,
      createdAt: widget.song?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (isEditing) {
      await DatabaseService.updateSong(song);
    } else {
      await DatabaseService.insertSong(song);
    }

    if (widget.albumId != null) {
      ref.invalidate(songsForAlbumProvider(widget.albumId!));
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить песню?'),
        content: Text('Удалить "${titleCtrl.text}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && widget.song != null) {
      await DatabaseService.deleteSong(widget.song!.id!);
      if (widget.albumId != null) {
        ref.invalidate(songsForAlbumProvider(widget.albumId!));
      }
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _sendToTelegram() async {
    final song = Song(
      id: widget.song!.id,
      albumId: widget.song!.albumId,
      title: titleCtrl.text,
      sections: [],
      rawText: lyricsCtrl.text,
    );
    final ok = await ExportImportService.sendSongToTelegram(song);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Отправлено' : 'Ошибка отправки')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать песню' : 'Новая песня'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Отправить в Telegram',
              onPressed: _sendToTelegram,
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Название'),
                      validator: (v) =>
                          v!.isEmpty ? 'Введите название' : null,
                    ),
                    const SizedBox(height: 12),
                    // Выбор альбома
                    DropdownButtonFormField<int?>(
                      value: _selectedAlbumId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Без альбома'),
                        ),
                        ..._albums.map((a) => DropdownMenuItem<int?>(
                              value: a.id,
                              child: Text(a.title),
                            )),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedAlbumId = val),
                      decoration: const InputDecoration(labelText: 'Альбом'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sectionLabels.map((label) {
                        return ActionChip(
                          label: Text(label),
                          onPressed: () => _insertSectionLabel(label),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: lyricsCtrl,
                      maxLines: null,
                      minLines: 10,
                      keyboardType: TextInputType.multiline,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Текст песни',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Введите текст песни' : null,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}