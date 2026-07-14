class DriveItem {
  final String id;
  final String name;
  final bool isFolder;
  final int size;
  final DateTime modified;
  final String ext;

  const DriveItem({
    required this.id,
    required this.name,
    required this.modified,
    this.isFolder = false,
    this.size = 0,
    this.ext = '',
  });
}

class DriveStub {
  DriveStub._();

  static final List<DriveItem> root = [
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
  ];

  static final List<DriveItem> documents = [
    DriveItem(
        id: 'd1',
        name: 'Resume 2026.pdf',
        size: 512000,
        modified: DateTime(2026, 6, 30),
        ext: 'pdf'),
    DriveItem(
        id: 'd2',
        name: 'Tax statement.pdf',
        size: 1153433,
        modified: DateTime(2026, 6, 18),
        ext: 'pdf'),
    DriveItem(
        id: 'd3',
        name: 'Meeting notes.md',
        size: 8192,
        modified: DateTime(2026, 7, 11),
        ext: 'md'),
    DriveItem(
        id: 'd4',
        name: 'Invoice template.docx',
        size: 76800,
        modified: DateTime(2026, 5, 27),
        ext: 'docx'),
  ];

  static List<DriveItem> itemsIn(List<String> path) {
    if (path.isEmpty) return root;
    if (path.length == 1 && path.first == 'Documents') return documents;
    return const [];
  }

  static List<DriveItem> get recent =>
      [...root, ...documents].where((i) => !i.isFolder).toList()
        ..sort((a, b) => b.modified.compareTo(a.modified));
}
