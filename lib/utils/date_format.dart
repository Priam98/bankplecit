/// Format helper untuk tanggal & label jenis transaksi.
String formatJenis(String jenis) {
  if (jenis.isEmpty) return 'Transaksi';
  return jenis[0].toUpperCase() + jenis.substring(1).toLowerCase();
}

String formatTanggal(DateTime tanggal) {
  if (tanggal.millisecondsSinceEpoch == 0) return '-';

  final day = tanggal.day.toString().padLeft(2, '0');
  final month = tanggal.month.toString().padLeft(2, '0');
  final year = tanggal.year.toString();
  final hour = tanggal.hour.toString().padLeft(2, '0');
  final minute = tanggal.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
