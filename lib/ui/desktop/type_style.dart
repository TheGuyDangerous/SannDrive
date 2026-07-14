import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../shared/models/drive_item.dart';

export '../../shared/core/format.dart';

IconData driveItemIcon(DriveItem item) {
  if (item.isFolder) return Iconsax.folder_2;
  switch (item.ext.toLowerCase()) {
    case 'mp4':
    case 'mkv':
    case 'mov':
    case 'avi':
    case 'webm':
      return Iconsax.video;
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'm4a':
    case 'ogg':
      return Iconsax.music;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
    case 'svg':
      return Iconsax.gallery;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return Iconsax.archive_1;
    case 'pdf':
    case 'doc':
    case 'docx':
    case 'txt':
    case 'md':
    case 'xls':
    case 'xlsx':
    case 'ppt':
    case 'pptx':
      return Iconsax.document_text;
    default:
      return Iconsax.document;
  }
}

Color driveItemColor(BuildContext context, DriveItem item) {
  if (item.isFolder) return Theme.of(context).colorScheme.primary;
  var h = 0;
  for (final c in item.ext.toLowerCase().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return HSLColor.fromAHSL(1, (h % 360).toDouble(), 0.59, 0.60).toColor();
}

Color driveItemChipColor(BuildContext context, DriveItem item) => item.isFolder
    ? Theme.of(context).colorScheme.primary.withOpacity(0.20)
    : driveItemColor(context, item).withOpacity(0.12);

class TypeIconChip extends StatelessWidget {
  const TypeIconChip({super.key, required this.item, this.size = 32});

  final DriveItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: driveItemChipColor(context, item),
        borderRadius: BorderRadius.circular(size >= 40 ? 12 : 10),
      ),
      child: Icon(
        driveItemIcon(item),
        size: size * 0.55,
        color: driveItemColor(context, item),
      ),
    );
  }
}
