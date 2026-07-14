import 'package:flutter_test/flutter_test.dart';
import 'package:sanndrive/shared/models/drive_item.dart';
import 'package:sanndrive/shared/services/index/drive_index.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late DriveIndex index;

  setUp(() {
    index = DriveIndex(
        factory: databaseFactoryFfi, dbPath: inMemoryDatabasePath);
  });

  tearDown(() => index.close());

  DriveItem file(String id, String name,
          {String? parentId, int size = 10, DateTime? modified}) =>
      DriveItem(
        id: id,
        name: name,
        size: size,
        modified: modified ?? DateTime(2026, 7, 1),
        ext: extOf(name),
        parentId: parentId,
      );

  DriveItem folder(String id, String name, {String? parentId}) => DriveItem(
        id: id,
        name: name,
        isFolder: true,
        modified: DateTime(2026, 7, 1),
        parentId: parentId,
      );

  test('insert and children scope items to their parent, folders first',
      () async {
    await index.insert(folder('f1', 'Docs'));
    await index.insert(file('a', 'zebra.txt'));
    await index.insert(file('b', 'apple.txt'));
    await index.insert(file('c', 'nested.pdf', parentId: 'f1'));

    final root = await index.children(null);
    expect([for (final i in root) i.id], ['f1', 'b', 'a']);

    final inDocs = await index.children('f1');
    expect(inDocs.single.id, 'c');
    expect(inDocs.single.parentId, 'f1');
    expect(inDocs.single.ext, 'pdf');
  });

  test('search matches across the whole index, case-insensitive', () async {
    await index.insert(folder('f1', 'Reports'));
    await index.insert(file('a', 'Quarterly report.pdf'));
    await index.insert(file('b', 'notes.txt', parentId: 'f1'));
    await index.insert(file('c', 'REPORT-final.docx', parentId: 'f1'));

    final hits = await index.search('report');
    expect([for (final i in hits) i.id], containsAll(['f1', 'a', 'c']));
    expect(hits, hasLength(3));
    expect(await index.search('  '), isEmpty);
    expect(await index.search('%'), isEmpty);
  });

  test('rename updates name and recomputes ext for files', () async {
    await index.insert(file('a', 'draft.txt'));
    await index.insert(folder('f1', 'Old'));

    await index.rename('a', 'final.pdf');
    await index.rename('f1', 'New');

    final a = await index.item('a');
    expect(a!.name, 'final.pdf');
    expect(a.ext, 'pdf');
    final f = await index.item('f1');
    expect(f!.name, 'New');
    expect(f.ext, '');
  });

  test('delete removes an item and all of its descendants', () async {
    await index.insert(folder('f1', 'Top'));
    await index.insert(folder('f2', 'Inner', parentId: 'f1'));
    await index.insert(file('a', 'deep.txt', parentId: 'f2'));
    await index.insert(file('b', 'kept.txt'));

    await index.delete('f1');

    expect(await index.item('f1'), isNull);
    expect(await index.item('f2'), isNull);
    expect(await index.item('a'), isNull);
    expect((await index.children(null)).single.id, 'b');
  });

  test('recent lists files only, newest first', () async {
    await index.insert(folder('f1', 'Docs'));
    await index.insert(file('a', 'old.txt', modified: DateTime(2026, 6, 1)));
    await index
        .insert(file('b', 'new.txt', modified: DateTime(2026, 7, 10)));

    final recent = await index.recent();
    expect([for (final i in recent) i.id], ['b', 'a']);
  });

  test('seedIfEmpty populates once and never overwrites', () async {
    await index.seedIfEmpty();
    final root = await index.children(null);
    expect(root, isNotEmpty);
    expect(root.where((i) => i.isFolder).map((i) => i.name),
        contains('Documents'));

    final docs = root.firstWhere((i) => i.name == 'Documents');
    expect(await index.children(docs.id), isNotEmpty);

    await index.delete(root.first.id);
    final after = await index.children(null);
    await index.seedIfEmpty();
    expect(await index.children(null), hasLength(after.length));
  });
}
