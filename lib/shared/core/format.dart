String formatBytes(int bytes) {
  if (bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u++;
  }
  return u == 0 ? '$bytes B' : '${v.toStringAsFixed(1)} ${units[u]}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
