import 'package:flutter/material.dart';
import '../../services/jadwal_service.dart';
import '../../models/jadwal_model.dart';
import '../../utils/colors.dart';

class MahasiswaJadwalScreen extends StatefulWidget {
  final String npm;
  const MahasiswaJadwalScreen({super.key, required this.npm});

  @override
  State<MahasiswaJadwalScreen> createState() => _MahasiswaJadwalScreenState();
}

class _MahasiswaJadwalScreenState extends State<MahasiswaJadwalScreen> {
  List<Jadwal> jadwals = [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await JadwalService.getAllJadwal();
    setState(() {
      jadwals = all.where((j) => j.peserta.contains(widget.npm)).toList();
    });
  }

  int _weekdayFromString(String hari) {
    final dt = DateTime.tryParse(hari);
    if (dt != null) return dt.weekday;

    final normalized = hari.trim().toLowerCase();
    final map = {
      'senin': 1,
      'monday': 1,
      'selasa': 2,
      'tuesday': 2,
      'rabu': 3,
      'wednesday': 3,
      'kamis': 4,
      'thursday': 4,
      "jumat": 5,
      "jum'at": 5,
      'friday': 5,
      'sabtu': 6,
      'saturday': 6,
      'minggu': 7,
      'sunday': 7,
    };
    return map[normalized] ?? 7;
  }

  int _startMinutesFromJam(String jamStr) {
    final parts = jamStr.split('-');
    if (parts.isEmpty) return 0;
    final left = parts[0].trim();

    final ampmReg = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$');
    final m24Reg = RegExp(r'^(\d{1,2}):(\d{2})$');

    final ampmMatch = ampmReg.firstMatch(left);
    if (ampmMatch != null) {
      var hour = int.parse(ampmMatch.group(1)!);
      final minute = int.parse(ampmMatch.group(2)!);
      final ampm = ampmMatch.group(3)!.toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      return hour * 60 + minute;
    }

    final m24Match = m24Reg.firstMatch(left);
    if (m24Match != null) {
      final hour = int.parse(m24Match.group(1)!);
      final minute = int.parse(m24Match.group(2)!);
      return hour * 60 + minute;
    }

    return 0;
  }

  String _dayNameFromWeekday(int wd) {
    switch (wd) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      default:
        return 'Minggu';
    }
  }

  Map<int, List<Jadwal>> _groupedSorted() {
    final filtered = jadwals.where((j) {
      if (_filter.isEmpty) return true;
      return j.mataKuliah.toLowerCase().contains(_filter.toLowerCase()) ||
          j.id.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      final da = _weekdayFromString(a.hari);
      final db = _weekdayFromString(b.hari);
      if (da != db) return da - db;
      final sa = _startMinutesFromJam(a.jam);
      final sb = _startMinutesFromJam(b.jam);
      return sa.compareTo(sb);
    });

    final Map<int, List<Jadwal>> map = {};
    for (final j in filtered) {
      final wd = _weekdayFromString(j.hari);
      map.putIfAbsent(wd, () => []).add(j);
    }
    return map;
  }

  Widget _buildRightCell(Jadwal j) {
    final pertemuan = '1';
    final jamParts = j.jam.split('-').map((s) => s.trim()).toList();
    final jamMulai = jamParts.isNotEmpty ? jamParts[0] : '-';
    final jamSelesai = jamParts.length > 1 ? jamParts[1] : '-';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pertemuan',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 6),
          Text(pertemuan, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Nama Dosen: ${j.dosenNip}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text('Hari: ${j.hari}', style: const TextStyle(fontSize: 12)),
          Text('Jam: $jamMulai - $jamSelesai',
              style: const TextStyle(fontSize: 12)),
          Text('Ruang: ${j.ruang}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openDetailDialog(j),
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Detail'),
          ),
        ],
      ),
    );
  }

  void _openDetailDialog(Jadwal j) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(j.mataKuliah),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kode: ${j.id}'),
              const SizedBox(height: 6),
              Text('Hari: ${j.hari}'),
              Text('Jam: ${j.jam}'),
              Text('Ruang: ${j.ruang}'),
              Text('Dosen NIP: ${j.dosenNip}'),
              const SizedBox(height: 6),
              Text('Peserta: ${j.peserta.length} mahasiswa'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedSorted();
    final todayWd = DateTime.now().weekday;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Jadwal Kuliah'),
          backgroundColor: AppColors.primary),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cari kode atau mata kuliah...'),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('Refresh'),
                )
              ],
            ),
          ),

          Expanded(
            child: grouped.isEmpty
                ? const Center(child: Text('Belum ada jadwal untuk Anda.'))
                : ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    children: [
                      for (int d = 1; d <= 6; d++)
                        if (grouped.containsKey(d) &&
                            (grouped[d]?.isNotEmpty ?? false))
                          ...[
                            // --- Header Hari ---
                            Container(
                              width: double.infinity,
                              margin:
                                  const EdgeInsets.only(bottom: 8, top: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: d == todayWd
                                    ? AppColors.success.withOpacity(0.95)
                                    : AppColors.primary.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _dayNameFromWeekday(d),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),

                            // --- List Jadwal ---
                            for (final j in (grouped[d] ?? []))
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2))
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // KODE
                                    Container(
                                      width: 106,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius:
                                            const BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          bottomLeft: Radius.circular(10),
                                        ),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Kode',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Colors.black54),
                                          ),
                                          SizedBox(height: 8),
                                        ],
                                      ),
                                    ),

                                    // MATA KULIAH
                                    Expanded(
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12,
                                                horizontal: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              j.mataKuliah,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '(Kelas : A)',
                                              style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // DETAIL KANAN
                                    Container(
                                      width: 220,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                      child: _buildRightCell(j),
                                    ),
                                  ],
                                ),
                              ),
                          ], // TANPA KOMA DI SINI
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
