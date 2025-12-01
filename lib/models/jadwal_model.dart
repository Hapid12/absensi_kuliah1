import 'dart:convert';

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
  final text = pesertaField.trim();

  // Jika format JSON array: ["2301","2302"]
  if (text.startsWith('[') && text.endsWith(']')) {
    try {
      final List decoded = jsonDecode(text);
      pesertaList = decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      // fallback ke CSV biasa
      pesertaList = text
          .split(',')
          .map((e) => e.toString().replaceAll('"', '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  } else {
    // CSV normal
    pesertaList = text
        .split(',')
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
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
