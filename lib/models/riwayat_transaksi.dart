class RiwayatTransaksi {
  final String id;
  final String debiturId;
  final String namaDebitur;
  final String jenis;
  final double nominal;
  final DateTime tanggal;

  RiwayatTransaksi({
    required this.id,
    required this.debiturId,
    required this.namaDebitur,
    required this.jenis,
    required this.nominal,
    required this.tanggal,
  });

  factory RiwayatTransaksi.fromMap(Map<String, dynamic> map) {
    final tanggalValue =
        map['tanggal'] ??
        map['tanggal_transaksi'] ??
        map['created_at'] ??
        map['waktu_transaksi'];

    return RiwayatTransaksi(
      id: _stringValue(map, ['id', 'transaksi_id']),
      debiturId: _stringValue(map, ['debitur_id']),
      namaDebitur: _stringValue(map, ['nama_debitur', 'debitur_nama', 'nama']),
      jenis: _stringValue(map, ['jenis', 'tipe', 'tipe_transaksi', 'type']),
      nominal: _doubleValue(map, ['nominal', 'jumlah', 'total']),
      tanggal: tanggalValue is DateTime
          ? tanggalValue
          : DateTime.tryParse(tanggalValue?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isKasbon {
    final lowerJenis = jenis.toLowerCase();
    return lowerJenis.contains('kasbon') || lowerJenis.contains('utang');
  }
}

String _stringValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null) {
      return value.toString();
    }
  }

  return '';
}

double _doubleValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value.replaceAll('.', ''));
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return 0;
}
