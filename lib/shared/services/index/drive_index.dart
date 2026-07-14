import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../../models/drive_item.dart';

class DriveIndex {
  DriveIndex({sqflite.DatabaseFactory? factory, String? dbPath})
      : _factory = factory,
        _dbPath = dbPath;

  static const _version = 1;

  final sqflite.DatabaseFactory? _factory;
  final String? _dbPath;
  Future<sqflite.Database>? _opening;

  Future<sqflite.Database> get _db => _opening ??= _open();

  Future<sqflite.Database> _open() async {
    final factory = _factory ?? sqflite.databaseFactory;
    var path = _dbPath;
    if (path == null) {
      final dir = await getApplicationSupportDirectory();
      path = p.join(dir.path, 'drive_index.db');
    }
    return factory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: _version,
        onCreate: (db, version) async {
          await db.execute('''
CREATE TABLE items(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  is_folder INTEGER NOT NULL DEFAULT 0,
  parent_id TEXT,
  size_bytes INTEGER NOT NULL DEFAULT 0,
  modified_ms INTEGER NOT NULL,
  ext TEXT NOT NULL DEFAULT '',
  tg_message_id INTEGER,
  caption_tag TEXT
)''');
          await db.execute('CREATE INDEX idx_items_parent ON items(parent_id)');
        },
      ),
    );
  }

  Map<String, Object?> _toRow(DriveItem item) => {
        'id': item.id,
        'name': item.name,
        'is_folder': item.isFolder ? 1 : 0,
        'parent_id': item.parentId,
        'size_bytes': item.size,
        'modified_ms': item.modified.millisecondsSinceEpoch,
        'ext': item.ext,
        'tg_message_id': item.tgMessageId,
        'caption_tag': item.captionTag,
      };

  DriveItem _fromRow(Map<String, Object?> row) => DriveItem(
        id: row['id']! as String,
        name: row['name']! as String,
        isFolder: (row['is_folder']! as int) != 0,
        parentId: row['parent_id'] as String?,
        size: row['size_bytes']! as int,
        modified:
            DateTime.fromMillisecondsSinceEpoch(row['modified_ms']! as int),
        ext: row['ext']! as String,
        tgMessageId: row['tg_message_id'] as int?,
        captionTag: row['caption_tag'] as String?,
      );

  Future<void> insert(DriveItem item) async {
    final db = await _db;
    await db.insert('items', _toRow(item),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    final ids = <String>[id];
    var frontier = <String>[id];
    while (frontier.isNotEmpty) {
      final marks = List.filled(frontier.length, '?').join(',');
      final rows = await db.query('items',
          columns: ['id'], where: 'parent_id IN ($marks)', whereArgs: frontier);
      frontier = [for (final r in rows) r['id']! as String];
      ids.addAll(frontier);
    }
    final marks = List.filled(ids.length, '?').join(',');
    await db.delete('items', where: 'id IN ($marks)', whereArgs: ids);
  }

  Future<void> rename(String id, String name) async {
    final db = await _db;
    await db.update(
      'items',
      {'name': name, 'ext': extOf(name)},
      where: 'id = ? AND is_folder = 0',
      whereArgs: [id],
    );
    await db.update(
      'items',
      {'name': name},
      where: 'id = ? AND is_folder = 1',
      whereArgs: [id],
    );
  }

  Future<DriveItem?> item(String id) async {
    final db = await _db;
    final rows =
        await db.query('items', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<List<DriveItem>> children(String? parentId) async {
    final db = await _db;
    final rows = await db.query(
      'items',
      where: parentId == null ? 'parent_id IS NULL' : 'parent_id = ?',
      whereArgs: parentId == null ? null : [parentId],
      orderBy: 'is_folder DESC, name COLLATE NOCASE ASC',
    );
    return [for (final r in rows) _fromRow(r)];
  }

  Future<List<DriveItem>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final db = await _db;
    final escaped =
        q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    final rows = await db.query(
      'items',
      where: r"name LIKE ? ESCAPE '\'",
      whereArgs: ['%$escaped%'],
      orderBy: 'is_folder DESC, name COLLATE NOCASE ASC',
    );
    return [for (final r in rows) _fromRow(r)];
  }

  Future<List<DriveItem>> recent({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      'items',
      where: 'is_folder = 0',
      orderBy: 'modified_ms DESC',
      limit: limit,
    );
    return [for (final r in rows) _fromRow(r)];
  }

  Future<void> seedIfEmpty() async {
    final db = await _db;
    final count = sqflite.Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM items'));
    if (count != null && count > 0) return;
    final batch = db.batch();
    for (final item in _seedItems) {
      batch.insert('items', _toRow(item));
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    final db = await opening;
    await db.close();
  }
}

final _seedItems = <DriveItem>[
  DriveItem(
      id: 'f-docs',
      name: 'Documents',
      isFolder: true,
      modified: DateTime(2026, 7, 10)),
  DriveItem(
      id: 'r1',
      name: 'Aurora timelapse.mp4',
      size: 734003200,
      modified: DateTime(2026, 7, 12),
      ext: 'mp4'),
  DriveItem(
      id: 'r2',
      name: 'Coastline drone reel.mov',
      size: 1288490188,
      modified: DateTime(2026, 7, 8),
      ext: 'mov'),
  DriveItem(
      id: 'r3',
      name: 'Podcast episode 12.mp3',
      size: 58720256,
      modified: DateTime(2026, 7, 5),
      ext: 'mp3'),
  DriveItem(
      id: 'r4',
      name: 'Berlin trip 001.jpg',
      size: 4404019,
      modified: DateTime(2026, 6, 28),
      ext: 'jpg'),
  DriveItem(
      id: 'r5',
      name: 'Product hero.png',
      size: 8912896,
      modified: DateTime(2026, 7, 13),
      ext: 'png'),
  DriveItem(
      id: 'r6',
      name: 'Quarterly report.pdf',
      size: 2202009,
      modified: DateTime(2026, 7, 1),
      ext: 'pdf'),
  DriveItem(
      id: 'r7',
      name: 'Design system spec.pdf',
      size: 11534336,
      modified: DateTime(2026, 6, 21),
      ext: 'pdf'),
  DriveItem(
      id: 'r8',
      name: 'Website backup.zip',
      size: 3435973836,
      modified: DateTime(2026, 6, 14),
      ext: 'zip'),
  DriveItem(
      id: 'r9',
      name: 'Lecture notes.txt',
      size: 24576,
      modified: DateTime(2026, 7, 3),
      ext: 'txt'),
  DriveItem(
      id: 'd1',
      name: 'Resume 2026.pdf',
      parentId: 'f-docs',
      size: 512000,
      modified: DateTime(2026, 6, 30),
      ext: 'pdf'),
  DriveItem(
      id: 'd2',
      name: 'Tax statement.pdf',
      parentId: 'f-docs',
      size: 1153433,
      modified: DateTime(2026, 6, 18),
      ext: 'pdf'),
  DriveItem(
      id: 'd3',
      name: 'Meeting notes.md',
      parentId: 'f-docs',
      size: 8192,
      modified: DateTime(2026, 7, 11),
      ext: 'md'),
  DriveItem(
      id: 'd4',
      name: 'Invoice template.docx',
      parentId: 'f-docs',
      size: 76800,
      modified: DateTime(2026, 5, 27),
      ext: 'docx'),
];
