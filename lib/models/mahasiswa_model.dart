class Mahasiswa {
  final String id;
  final String npm;
  final String prodi;
  final String nama;
  final String status; // "Hadir", "Sakit", "Tidak Hadir"

  Mahasiswa({
    required this.id,
    required this.npm,
    required this.prodi,
    required this.nama,
    required this.status,
  });

  Mahasiswa copyWith({String? status}) {
    return Mahasiswa(
      id: id,
      npm: npm,
      prodi: prodi,
      nama: nama,
      status: status ?? this.status,
    );
  }

  factory Mahasiswa.fromMap(Map<String, dynamic> m) => Mahasiswa(
    id: m['id'],
    npm: m['npm'],
    prodi: m['prodi'],
    nama: m['nama'],
    status: m['status'] ?? 'Tidak Hadir',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'npm': npm,
    'prodi': prodi,
    'nama': nama,
    'status': status,
  };
}
