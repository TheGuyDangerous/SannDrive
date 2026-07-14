class DriveItem {
  final String id;
  final String name;
  final bool isFolder;
  final int size;
  final DateTime modified;
  final String ext;
  final String? parentId;
  final int? tgMessageId;
  final String? captionTag;

  const DriveItem({
    required this.id,
    required this.name,
    required this.modified,
    this.isFolder = false,
    this.size = 0,
    this.ext = '',
    this.parentId,
    this.tgMessageId,
    this.captionTag,
  });

  DriveItem copyWith({String? name, String? ext, String? parentId}) {
    return DriveItem(
      id: id,
      name: name ?? this.name,
      modified: modified,
      isFolder: isFolder,
      size: size,
      ext: ext ?? this.ext,
      parentId: parentId ?? this.parentId,
      tgMessageId: tgMessageId,
      captionTag: captionTag,
    );
  }
}

String extOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}
