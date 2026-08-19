class DebiturSummary {
  final String id;
  final String nama;
  final double totalKasbon;
  final double totalPembayaran;
  final double sisa;
  final String status;

  DebiturSummary({
    required this.id,
    required this.nama,
    required this.totalKasbon,
    required this.totalPembayaran,
    required this.sisa,
    required this.status,
  });

  factory DebiturSummary.fromMap(Map<String, dynamic> map) {
    return DebiturSummary(
      id: map['id'] as String,
      nama: map['nama'] as String,
      totalKasbon: (map['total_kasbon'] as num).toDouble(),
      totalPembayaran: (map['total_pembayaran'] as num).toDouble(),
      sisa: (map['sisa'] as num).toDouble(),
      status: map['status'] as String,
    );
  }
}