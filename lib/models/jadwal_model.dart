class Jadwal {
  final String id;
  final String mataKuliah;
  final String hari;
  final String jam;
  final String ruang;
  final String dosenNip;
  final List<String> peserta; // list of mahasiswa npm

  Jadwal({
    required this.id,
    required this.mataKuliah,
    required this.hari,
    required this.jam,
    required this.ruang,
    required this.dosenNip,
    List<String>? peserta,
  }) : peserta = peserta ?? [];

  // factory to parse from a Map and accept different peserta formats (String or List)
  factory Jadwal.fromMap(Map<String, dynamic> map) {
    final pesertaField = map['peserta'];
    List<String> pesertaList = [];

    if (pesertaField == null) {
      pesertaList = [];
    } else if (pesertaField is String) {
      // support comma separated string like "2301,2302"
      pesertaList = pesertaField
          .split(',')
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (pesertaField is List) {
      pesertaList = pesertaField
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      pesertaList = [pesertaField.toString().trim()];
    }

    return Jadwal(
      id: map['id']?.toString() ?? '',
      mataKuliah: map['mataKuliah']?.toString() ?? '',
      hari: map['hari']?.toString() ?? '',
      jam: map['jam']?.toString() ?? '',
      ruang: map['ruang']?.toString() ?? '',
      dosenNip: map['dosenNip']?.toString() ?? '',
      peserta: pesertaList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mataKuliah': mataKuliah,
      'hari': hari,
      'jam': jam,
      'ruang': ruang,
      'dosenNip': dosenNip,
      'peserta': peserta,
    };
  }
}
