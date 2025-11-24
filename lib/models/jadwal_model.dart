class Jadwal {
  final String id;
  final String mataKuliah;
  final String hari;
  final String jam;
  final String ruang;
  final String dosenNip;
  final List<String> peserta; // list of mahasiswa npm

  Jadwal({required this.id, required this.mataKuliah, required this.hari, required this.jam, required this.ruang, required this.dosenNip, List<String>? peserta}) : peserta = peserta ?? [];
}

