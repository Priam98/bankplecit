class TransaksiKas {
  final String id;
  final String jenis;
  final double nominal;
  final String? keterangan;
  final DateTime tanggal;
  final DateTime createdAt;

  const TransaksiKas({
    required this.id,
    required this.jenis,
    required this.nominal,
    this.keterangan,
    required this.tanggal,
    required this.createdAt,
  });

  factory
  TransaksiKas.fromMap(Map<String, dynamic> map) {
      return TransaksiKas(
        id: map['id'] as String,
        jenis: map['jenis'] as String,
        nominal: (map['nominal'] as num).toDouble(),
        keterangan: map['keterangan'] as String?,
        tanggal: DateTime.parse(map['tanggal'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }
  bool get isMasuk => jenis == 'masuk';
  bool get isKeluar => jenis == 'keluar';  
}