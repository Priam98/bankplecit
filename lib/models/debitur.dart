import 'kasbon.dart';
import 'pembayaran.dart';

class Debitur {
  final String id;
  final String nama;
  final List<Kasbon> kasbon;
  final List<Pembayaran> pembayaran;

  Debitur({
    required this.id,
    required this.nama,
    required this.kasbon,
    required this.pembayaran,
  });
  double get totalKasbon {
    return kasbon.fold(0.0, (total, item) => total + item.nominal.abs());
  }

  double get totalPembayaran {
    return pembayaran.fold(0.0, (total, item) => total + item.nominal.abs());
  }

  double get sisa {
    final hasil = totalKasbon - totalPembayaran;
    return hasil < 0 ? 0 : hasil;
  }

  double get kelebihanBayar {
    return totalPembayaran > totalKasbon
        ? totalPembayaran - totalKasbon
        : 0;
  }

}
